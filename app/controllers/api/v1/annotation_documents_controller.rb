module API
  module V1
    class AnnotationDocumentsController < BaseController
      include Swagger::Blocks

      before_action :set_annotation_document, only: [:show, :update, :destroy]

      swagger_path '/annotation_documents/{id}' do
        operation :get do
          key :comsumes, ['application/json']
          key :description, 'Returns an annotation document'
          key :operationId, 'annotation_document_read'
          key :produces, ['application/json']
          key :tags, ['AnnotationDocuments']

          parameter name: :id do
            key :in, :path
            key :required, true
            key :type, :integer
            key :format, :int32
          end

          response 200 do
            key :description, I18n.t('api.annotation_document.show.response-200')
            schema do
              key :'$ref', :AnnotationDocument
            end
          end

          response 400 do
            key :description, I18n.t('api.annotation_document.show.response-400')
            schema do
              key :'$ref', :ErrorModel
            end
          end
        end
      end

      swagger_path '/annotation_documents' do
        operation :post do
          key :comsumes, ['application/json']
          key :description, 'Creates a new annotation document'
          key :operationId, 'annotation_document_create'
          key :produces, ['application/json']
          key :tags, ['AnnotationDocuments']

          parameter name: :json_object do
            key :in, :body
            key :required, true
            schema do
              key :'$ref', :AnnotationDocument
            end
          end

          response 200 do
            key :description, I18n.t('api.annotation_document.create.response-200')
            schema do
              key :'$ref', :AnnotationDocument
            end
          end

          response 400 do
            key :description, I18n.t('api.annotation_document.create.response-400')
            schema do
              key :'$ref', :ErrorModel
            end
          end
        end
      end

      def create
        @annotation_document = AnnotationDocument.new(annotation_document_params)
        if @annotation_document.save
          render json: @annotation_document
        else
          render status: 400,
                 json: {
                   message: I18n.t('api.annotation_document.create.error'),
                   validationErrors: @annotation_document.errors.full_messages
                 }
        end
      rescue ArgumentError
        return_parameter_type_mismatch
      end

      def show
        render json: @annotation_document.relevat_attributes
      end

      private

        def set_annotation_document
          @annotation_document = AnnotationDocument.find(params[:id])
        rescue #RecordNotFound
          render status: 400,
                 json: {
                   message: I18n.t('api.annotation_document.show.error')
                 }
        end

        def return_parameter_type_mismatch
          render status: 400,
                 json: {
                   message: I18n.t('api.annotation_document.general-errors.parameter-type-mismatch')
                 }
        end

        def annotation_document_params
          parameters = params.require(:annotation_document).permit(
            :id,
            :chunk_offset,
            :content,
            :label,
            :options,
            :raw_datum_id,
            :interface_type
          )
          parameters[:options] = params[:options]
          parameters
        end
    end
  end
end
