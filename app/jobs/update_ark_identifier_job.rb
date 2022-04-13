# Update ARK identifier for media objects when published
#
# University of Houston
# author: Sean Watkins <slwatkins@uh.edu>

module UpdateArkIdentifierJob
  class Create < ActiveJob::Base
    include Rails.application.routes.url_helpers

    queue_as :update_ark_identifier
    def perform(media_object_id)
      @media_object = MediaObject.find(media_object_id)
      if self.identifier?
        ark_id = self.identifier
        @ark = UpdateArkIdentifierJob::Ark.new
        @ark.id = ark_id
        @ark.where = media_object_url(@media_object)
        @ark.save      
        Rails.logger.info "Update ARK #{ark_id} for #{media_object_id}"

        # Need Avalon to house the full ARK URL
        ids = @media_object.other_identifier ||= []
        ids.each.with_index do |id, index|
          if id[:source] == 'digital object'
            Rails.logger.info "#{ark_id}"
            ids[index][:id] = Settings.greens.base_uri + ark_id
          end
        end
        @media_object.other_identifier = ids
        @media_object.save( validate: false )
      end
    end

    def identifier? 
      ids = @media_object.other_identifier ||= []
      ids.each do |i|
        if i[:source] == 'digital object'
          return !i[:id].blank?
        end
      end
      return false
    end

    def identifier 
      ids = @media_object.other_identifier ||= []
      ids.each do |i|
        if i[:source] == 'digital object'
          return i[:id].match(/(ark:\/[0-9a-z\/]+)/).to_s
        end
      end
      return ''
    end
  end

  class ArkProxy < Flexirest::ProxyBase
    get "/id/:id" do
      response = passthrough
      translate(response) do |body|
        body = body["ark"]
        body
      end
    end
  end

  class Ark < Flexirest::Base
    proxy UpdateArkIdentifierJob::ArkProxy
    base_url Settings.greens.endpoint

    before_request :add_authentication_details

    perform_caching false

    get :find, "/id/:id"
    put :save, "/id/:id"
    post :create, "/arks/mint/" + Settings.greens.prefix

    def add_authentication_details(name, request)
      request.headers["api-key"] = Settings.greens.api_key
    end

  end

end
