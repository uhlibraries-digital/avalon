# Insert DO into ASpace and attach it to the given archival object
#
# University of Houston
# author: Sean Watkins <slwatkins@uh.edu>

require 'securerandom'
module InsertAspaceDigitalObjectJob

  class Config
    def initialize
      @config = load_configuration
    end

    def config_file
      Rails.root.join('config', 'archivesspace.yml')
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

    queue_as :insert_aspace_digital_object_create
    def perform(media_object_id)
      @media_object = MediaObject.find(media_object_id)
      aspace_uri = self.aspace_uri
      ark_url = self.identifier

      if !aspace_uri.blank? and !ark_url.blank?
        @archival_object = InsertAspaceDigitalObjectJob::ArchivalObject.find(aspace_uri)
        repository_id = /\/repositories\/(\d+)/.match(@archival_object.repository.ref)[1]
        if !has_do_ark ark_url
          Rails.logger.info "Adding Digital Object to #{aspace_uri}"
          new_do = new_aspace_do ark_url
          @digital_object = InsertAspaceDigitalObjectJob::DigitalObject.create(
            repo_id: repository_id,
            digital_object: new_do)
          new_instance = new_aspace_instance @digital_object.uri
          @archival_object.instances << new_instance
          @archival_object.id = @archival_object.uri
          @archival_object.save

          # Need Avalon to house the full ASpace URL
          ids = @media_object.other_identifier ||= []
          ids.each.with_index do |id, index|
            if id[:source] == 'aspace uri'
              ids[index][:id] = InsertAspaceDigitalObjectJob::Configuration.lookup('frontend') + aspace_uri
            end
          end
          @media_object.other_identifier = ids
          @media_object.save( validate: false )
        else
          Rails.logger.info "Digtal object for #{ark_url} already exists"
        end
      else
        Rails.logger.info "Couldn't find aspace uri and/or ark uri, I won't be doing anything"
      end
    end

    def has_do_ark(ark_url)
      @archival_object.instances.each do |instance|
        if instance.instance_type == "digital_object"
          digital_object = InsertAspaceDigitalObjectJob::DigitalObject.find(instance.digital_object.ref)
          digital_object.file_versions.each do |file|
            if file.file_uri == ark_url
              return true
            end
          end
        end
      end
      return false
    end

    def aspace_uri
      ids = @media_object.other_identifier ||= []
      ids.each do |i|
        if i[:source] == 'aspace uri'
          return i[:id].match(/(\/repositories\/\d+\/.*$)/).to_s
        end
      end
      return ''
    end

    def identifier
      ids = @media_object.other_identifier ||= []
      ids.each do |i|
        if i[:source] == 'digital object'
          return i[:id]
        end
      end
      return ''
    end

    def new_aspace_do(ark_url)
      return {
        "jsonmodel_type": "digital_object",
        "digital_object_id": SecureRandom.uuid,
        "external_ids": [],
        "subjects": [],
        "linked_events": [],
        "extends": [],
        "dates": [],
        "external_documents": [],
        "rights_statements": [],
        "linked_agents": [],
        "file_versions": [
          {
            "jsonmodel_type": "file_version",
            "is_representative": false,
            "file_uri": ark_url,
            "use_statement": "",
            "xlink_actuate_attribute": "",
            "xlink_show_attribute": "",
            "file_format_name": "",
            "file_format_version": "",
            "checksum": "",
            "checksum_method": ""
          }
        ],
        "restrictions": false,
        "notes": [],
        "linked_instances": [],
        "title": @media_object.title.presence + " (Access)",
        "language": ""
      }
    end

    def new_aspace_instance(uri)
      return {
        "jsonmodel_type": "instance",
        "digital_object": {
            "ref": uri
        },
        "instance_type": "digital_object",
        "is_representative": false
      }
    end
  end

  class ArchivalObject < Flexirest::Base
    base_url InsertAspaceDigitalObjectJob::Configuration.lookup('endpoint')

    before_request :add_authentication_details
    before_request :replace_body

    perform_caching false
    request_body_type :json

    get :find, ":id"
    post :save, ":id"
    post :create, "/repositories/:repo_id/archival_objects"

    def add_authentication_details(name, request)
      @session = InsertAspaceDigitalObjectJob::Session._request(
        InsertAspaceDigitalObjectJob::Configuration.lookup('endpoint') + '/users/' +
        InsertAspaceDigitalObjectJob::Configuration.lookup('username') + '/login',
        :post,
        {password: InsertAspaceDigitalObjectJob::Configuration.lookup('password')}
      )
      request.headers["X-ArchivesSpace-Session"] = @session.session
    end

    def replace_body(name, request)
      if name == :save
        request.body = request.post_params.to_json
      end
    end
  end

  class DigitalObject < Flexirest::Base
    base_url InsertAspaceDigitalObjectJob::Configuration.lookup('endpoint')
    perform_caching false
    request_body_type :json

    before_request :add_authentication_details
    before_request :replace_body

    get :find, ":id"
    post :create, "/repositories/:repo_id/digital_objects"

    def add_authentication_details(name, request)
      @session = InsertAspaceDigitalObjectJob::Session._request(
        InsertAspaceDigitalObjectJob::Configuration.lookup('endpoint') + '/users/' +
        InsertAspaceDigitalObjectJob::Configuration.lookup('username') + '/login',
        :post,
        {password: InsertAspaceDigitalObjectJob::Configuration.lookup('password')}
      )
      request.headers["X-ArchivesSpace-Session"] = @session.session
    end

    def replace_body(name, request)
      if name == :create
        request.body = request.post_params[:digital_object].to_json
      end
    end
  end

  class Session < Flexirest::Base
  end

end
