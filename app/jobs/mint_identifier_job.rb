# Mints ARK identifier for media objects when published
#
# University of Houston
# author: Sean Watkins <slwatkins@uh.edu>

module MintIdentifierJob

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

    queue_as :mint_identifier_create
    def perform(media_object_id)
      @media_object = MediaObject.find(media_object_id)
      if !self.identifier?
        @ark = MintIdentifierJob::Ark.create(
          who:  @media_object.creator.empty? ? 'unknown' : @media_object.creator.join("; "),
          what: @media_object.title.presence || 'unknown',
          when: @media_object.date_issued.presence || 'unknown',
          where: media_object_url(@media_object)
        )
        Rails.logger.info "Minted ARK #{@ark.id} for #{media_object_id}"
        ids = @media_object.other_identifier ||= []
        ids << {
          source: 'digital object',
          id: MintIdentifierJob::Configuration.lookup('base_uri') + @ark.id
        }
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
    proxy MintIdentifierJob::ArkProxy
    base_url MintIdentifierJob::Configuration.lookup('endpoint')

    before_request :add_authentication_details

    perform_caching false

    get :find, "/id/:id"
    put :save, "/id/:id"
    post :create, "/arks/mint/" + MintIdentifierJob::Configuration.lookup('prefix')

    def add_authentication_details(name, request)
      request.headers["api-key"] = MintIdentifierJob::Configuration.lookup('api_key')
    end

  end

end
