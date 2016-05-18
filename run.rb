require 'bundler/setup'
require 'sinatra/base'
require "pry"

Config = {
  plaintext_password: 'test',
  uploaded_files: Set.new()
  # "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff"
}




class PhotobackupTestServer < Sinatra::Base

  def authorize!
    unless params['password'] == Digest::SHA512.hexdigest(Config[:plaintext_password])
      halt 403, "Access denied."
    end
  end

  get "/" do
    "This is the Photobackup Test-Server.\n\nThe configured password is: #{Config[:plaintext_password]}\n\nAvailable routes:\nPOST /\nPOST /test"
  end

  post "/test" do
    authorize!
    "OK!"
  end

  post "/" do
    authorize!
    unless params['upfile']
      halt 401, 'no upfile specified'
    end
    unless params['filesize'].to_i > 0
      halt 400, 'no filesize specified'
    end
    tempfile = params['upfile'][:tempfile]
    if !tempfile.size == params['filesize'].to_i
      halt 411, 'specified filesize and size of uploaded file not equal'
    end
    md5 = Digest::MD5.file(tempfile.path).to_s
    if Config[:uploaded_files].include?(md5)
      halt 409, 'file already uploaded'
    end
    file_mime_type = `file #{Shellwords.escape(tempfile.path)} --mime-type`.split(':').last.strip
    case file_mime_type
    when %r{image/|video/}
      Config[:uploaded_files] << md5
      "OK"
    else
      halt 401, "unhandled mime-type of upfile: #{file_mime_type}"
    end
  end

  post "/reset" do
    Config[:uploaded_files] = Set.new()
    "OK"
  end

end
