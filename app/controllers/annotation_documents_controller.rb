class AnnotationDocumentsController < ApplicationController
  include ErrorResponse

  # the order of the following before actions matters, since setters rely on each other
  before_action :authenticate_user,
                only: [:next]
  before_action :authenticate_admin!,
                except: [:next]
  before_action :set_project,
                only: [
                  :destroy_all,
                  :index,
                  :next,
                  :show
                ]
  before_action :set_raw_datum,
               only: [:index]
  before_action :set_annotation_documents, only: [:index, :destroy_all]
  before_action :set_annotation_document,
                only: [:show]

  # GET /projects/1/annotation_documents
  # GET /projects/1/raw_data/1/annotation_documents
  def index
    annotation_documents = @annotation_documents.order(rank: :asc)
    annotation_documents = annotation_documents.where(raw_datum: @raw_datum) if @raw_datum
    per_page = Rails.configuration.x.dalphi['paginated-objects-per-page']['annotation-documents']
    @annotation_documents = annotation_documents
                              .paginate(
                                page: params[:page],
                                per_page: per_page
                              )
  end

  # GET /projects/1/annotation_documents/1
  # GET /projects/1/raw_data/1/annotation_documents/1
  def show
  end

  INITIAL_DALPHI_COMMIT_DATETIME = DateTime.parse '07.03.2016 09:39:24 MEZ'

  # PATCH /projects/1/annotation_documents/next?count=10
  def next
    documents = annotation_documents(annotation_document_params['count'])

    if documents.count == 0
      render_annotation_document_errors 404, 'next.no-documents'

    elsif documents.update(requested_at: Time.zone.now)
      render json: documents.map{ |document| document.relevant_attributes }

    else
      render_annotation_document_errors 500, 'next.update-failed'
    end
  end

  def destroy_all
    @annotation_documents.destroy_all
    redirect_to project_annotation_documents_path(@project),
                notice: I18n.t('annotation-documents.action.destroy.success')
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = current_role.projects.find(params[:project_id])
    rescue
      render_annotation_document_errors 400, 'set-project.not-found'
    end

    def set_raw_datum
      raw_datum_id = params[:raw_datum_id]
      @raw_datum = RawDatum.find(raw_datum_id) if raw_datum_id
    rescue
      @raw_datum = false
    end

    def set_annotation_document
      @annotation_document = @project.annotation_documents.find(params[:id])
    end

    def set_annotation_documents
      @annotation_documents = @project.annotation_documents
    end

    def annotation_documents(count)
      count = 1 unless count
      timeout = Rails.configuration.x.dalphi['timeouts']['annotation-document-edit-time']
      time_range = INITIAL_DALPHI_COMMIT_DATETIME..(Time.zone.now - timeout.minutes)

      @project.annotation_documents.where(skipped: nil,
                                          requested_at: [nil, time_range])
                                   .order(rank: :asc)
                                   .limit(count)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def annotation_document_params
      params.permit(
        :count,
        :project_id
      )
    end
end
