require 'base64'
require 'yajl'
require 'openssl'
require 'date'

module Fernet
  class Generator
    attr_accessor :data, :payload

    def initialize(secret, encrypt)
      @secret  = Secret.new(secret, encrypt)
      @encrypt = encrypt
      @payload = ''
      @data    = {}
    end

    def generate
      yield self if block_given?
      data.merge!(:issued_at => Time.now.to_i)

      if encrypt?
        iv = encrypt_data!
        @payload = "#{base64(data)}|#{base64(iv)}"
      else
        @payload = base64(Yajl::Encoder.encode(data))
      end

      mac = OpenSSL::HMAC.hexdigest('sha256', secret.signing_key, payload)
      "#{payload}|#{mac}"
    end

    def inspect
      "#<Fernet::Generator @secret=[masked] @data=#{@data.inspect}>"
    end
    alias to_s inspect

    def data
      @data ||= {}
    end

  private
    attr_reader :secret

    def encrypt_data!
      cipher = OpenSSL::Cipher.new('AES-128-CBC')
      cipher.encrypt
      iv         = cipher.random_iv
      cipher.iv  = iv
      cipher.key = secret.encryption_key
      @data = cipher.update(Yajl::Encoder.encode(data)) + cipher.final
      iv
    end

    def base64(chars)
      Base64.urlsafe_encode64(chars)
    end

    def encrypt?
      @encrypt
    end

  end
end
