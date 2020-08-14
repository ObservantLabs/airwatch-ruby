module Airwatch
  class Client
  	# @param [String] host make sure you get this from Settings > System > Advanced > Site URLs
	def initialize(host_name, api_key, email: nil, password: nil, authorization: nil)
		@host_name = host_name
		@api_key = api_key

		if email && password
			@authorization = "Basic #{Base64.strict_encode64("#{email}:#{password}")}"
		elsif authorization
			@authorization = authorization
		else
			raise 'must provide (email & password) or authorization'
		end
	end

	#############################
	# Apps      				#
	#############################

	# @param [String] (optional) bundleid the app's bundle identifier, or nil
	# @param [String] (optional) type 'app' or nill
	# @param [String] (optional) applicationtype 'internal' or nil
	def apps_search(**args)
		params = args.to_h
		get('mam/apps/search', params)
	end

	# returns a list of device IDs that the app is installed on
	def app_devices(app_id)
		get("mam/apps/internal/#{app_id}/devices")
	end

	def install_internal_app(app_id, device_id)
		post("mam/apps/internal/#{app_id}/install", { deviceid: device_id })
	end

	#############################
	# Profiles  				#
	#############################

	# @see page 722 of AirWatch REST API docs
	def profiles_platforms_apple_create
	end

	# @see page 1034 of AirWatch REST API docs
	# @param [String] profile_id the AirWatch profile ID
	# @param [Integer] device_id the AirWatch device ID
	#
	# This method is idempotent.
	def profiles_install(profile_id, device_id: nil, serial_number: nil)
		params = {}

		unless device_id.nil?
			params[:deviceid] = device_id
		end

		unless serial_number.nil?
			params[:serialnumber] = serial_number
		end

		post("mdm/profiles/#{profile_id}/install", params)
	end

	# @see page 1034 of AirWatch REST API docs
	# @param [String] profile_id the AirWatch profile ID
	# @param [Integer] device_id the AirWatch device ID
	#
	# This method is NOT idempotent; after the first successful call, subsequent calls will return HTTP 400. 
	def profiles_remove(profile_id, device_id)
		post("mdm/profiles/#{profile_id}/remove", { deviceid: device_id })
	end

	#############################
	# Smart groups 				#
	#############################

	def smart_groups_search
		get('mdm/smartgroups/search')
	end

	# @see page 1173 of AirWatch REST API docs
	#
	# returns the list of apps assigned to Smart Group.
	def smart_group_apps(smart_group_id)
		get("mdm/smartgroups/#{smart_group_id}/apps")
	end

	def smart_group_details(smart_group_id)
		get("mdm/smartgroups/#{smart_group_id}")
	end

	#############################
	# Devices           		#
	#############################

	def device_details(device_id)
		get("mdm/devices/#{device_id}")
	end

	def device_profile_details(device_id: nil, serial_number: nil)
		params = {}

		unless device_id.nil?
			params[:searchby] = 'deviceid'
			params[:id] = device_id
		end

		unless serial_number.nil?
			params[:searchby] = 'serialnumber'
			params[:id] = serial_number
		end

		get('mdm/devices/profiles', params)
	end

	#############################
	# HTTP request stuff		#
	#############################

	def get(resource, params = {})
		url = build_url(resource, params)
		HTTParty.get(url, { headers: request_headers })
	end

	def put(resource, params = {})
		url = build_url(resource)
		HTTParty.put(url, { headers: request_headers, body: params })
	end

	def post(resource, params = {})
		url = build_url(resource)
		HTTParty.post(url, { headers: request_headers, body: params })
	end

	def pretty_get(resource, params = {})
		response = get(resource, params)
		unless response.code == 200
			puts response
			puts "⚠️  HTTP #{response.code}"
			return
		end
		puts JSON.pretty_generate(response.parsed_response)
	end

	def upload_blob(file_path, org_group_id)
		raise "No IPA found at path: #{file_path}" unless File.file?(file_path)
		filename = File.basename(file_path)
		url = build_url('mam/blobs/uploadblob', { filename: filename, organizationgroupid: org_group_id })
		payload = File.open(file_path, 'rb')
		headers = request_headers
		headers[:'Content-Type'] = 'application/octet-stream'
		headers[:'Expect'] = '100-continue'
		response = RestClient::Request.execute(
			:url => url,
			:method => :post,
			:headers => headers,
			:payload => File.open(file_path, 'rb')
		)
	end

	# private
	def request_headers
		{
			'aw-tenant-code': @api_key,
			'Accept': 'application/json',
			'Authorization': @authorization
		}
	end

	def build_url(resource, query_params = nil)
		url = "https://#{@host_name}/api/#{resource}"
		return url if query_params.nil?
		template = Addressable::Template.new("#{url}{?query*}")
		template.expand(query: query_params).to_s
	end
  end
end
