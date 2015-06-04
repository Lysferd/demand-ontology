
# Password Hashing With PBKDF2 (http://crackstation.net/hashing-security.htm).
# Copyright (c) 2013, Taylor Hornby
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, 
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation 
# and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
 
require( 'securerandom' )
require( 'openssl' )
require( 'base64' )

class User < ActiveRecord::Base

  PBKDF2_ITERATIONS = 512_000
  SALT_BYTE_SIZE = 32
  HASH_BYTE_SIZE = 32
  HASH_SECTIONS = 4
  SECTION_DELIMITER = ':'
  ITERATIONS_INDEX = 1
  SALT_INDEX = 2
  HASH_INDEX = 3

  attr_accessor( :password_confirmation )
  attr_reader( :password )

  before_create { generate_token :auth_token }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :password, confirmation: true, length: { minimum: 6 }
  validate :password_must_be_present

  has_many :datasets

  class << self
    def authenticate( email, password )
      user = find_by_email( email )
      return user if user and user.validate_password( password )
      return false
    end
  end


    def password_must_be_present
      errors.add( :password, 'Missing password' ) unless hashed_password.present?
    end

    def password=( password )
      @password = password
      self.hashed_password = encrypt_password( password ) if password.present?
    end

    def encrypt_password( password )
      salt = SecureRandom::base64( SALT_BYTE_SIZE )
      pbkdf2 = OpenSSL::PKCS5::pbkdf2_hmac_sha1(
        password,
        salt,
        PBKDF2_ITERATIONS,
        HASH_BYTE_SIZE
      )
      return [ 'sha1', PBKDF2_ITERATIONS, salt, Base64::strict_encode64( pbkdf2 ) ].
        join( SECTION_DELIMITER )
    end

    def validate_password( password )
      hashes = self.hashed_password.split( SECTION_DELIMITER )
      return false unless hashes.length == HASH_SECTIONS

      pbkdf2 = Base64::decode64( hashes[HASH_INDEX] )
      validation_hash = OpenSSL::PKCS5::pbkdf2_hmac_sha1(
        password, hashes[SALT_INDEX],
        hashes[ITERATIONS_INDEX].to_i,
        pbkdf2.length
      )
      return pbkdf2 == validation_hash
    end

    def generate_token( column )
      loop do
        self[column] = SecureRandom::urlsafe_base64
        break unless User::exists?( column => self[column] )
      end
    end
end
