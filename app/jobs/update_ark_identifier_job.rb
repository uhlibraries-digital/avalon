# Update ARK identifier for media objects when published
#
# University of Houston
# author: Sean Watkins <slwatkins@uh.edu>

module UpdateArkIdentifierJob

  class Config
    def initialize
      @config = load_configuration
    end

    def config_file
      Rails.root.join('config', 'minter.yml')
    end

    def load_configuration
      if File.exists?(config_file)
        load_configuration_from_file
      end
    end

    def load_configuration_from_file
      env = ENV['RAILS_ENV'] || 'development'
      YAML::load(File.read(config_file))[env]
    end

    def lookup(key)
      return @config[key].to_s
    end
  end

  Configuration = Config.new

  class Create < ActiveJob::Base
    include Rails.application.routes.url_helpers

    queue_as :update_ark_identifier_create
    def perform(media_object_id)
      @media_object = MediaObject.find(media_object_id)
      if self.identifier?
        @ark = UpdateArkIdentifierJob::Ark.new
        @ark.id = self.identifier
        @ark.where = media_object_url(@media_object)
        @ark.save
        Rails.logger.info "Update ARK #{@ark.id} for #{media_object_id}"

        # Need Avalon to house the full ARK URL
        ids = $media_object.other_identifier ||= []
        ids.each.with_index do |id, index|
          if id[:source] == 'digital object'
            ids[index][:id] = MintIdentifierJob::Configuration.lookup('base_uri') + @ark.id
          end
        end
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
  end

  def indenifier
    ids = @media_object.other_identifier ||= []
    ids.each do |i|
      if i[:source] == 'digital object'
        return i[:id].match(/(ark:\/[0-9a-z\/]+)/).to_s
      end
    end
    return ''
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
    base_url UpdateArkIdentifierJob::Configuration.lookup('endpoint')

    before_request :add_authentication_details

    perform_caching false

    get :find, "/id/:id"
    put :save, "/id/:id"
    post :create, "/arks/mint/" + UpdateArkIdentifierJob::Configuration.lookup('prefix')

    def add_authentication_details(name, request)
      request.headers["api-key"] = UpdateArkIdentifierJob::Configuration.lookup('api_key')
    end

  end

end
