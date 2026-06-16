# typed: strict
# frozen_string_literal: true

require "dependabot/version"
require "dependabot/utils"

module Dependabot
  module Wordpress
    class Version < Dependabot::Version
      extend T::Sig

      WORDPRESS_VERSION_PATTERN = /[0-9]+(?:\.[0-9]+)*(?:-[a-zA-Z0-9.]+)?/
      ANCHORED_WORDPRESS_VERSION_PATTERN = /\A#{WORDPRESS_VERSION_PATTERN}\z/

      sig { override.params(version: VersionParameter).returns(T::Boolean) }
      def self.correct?(version)
        return true if version.is_a?(Gem::Version)

        version_str = version.to_s
        return false if version_str.empty?
        return true if version_str.match?(ANCHORED_WORDPRESS_VERSION_PATTERN)

        Gem::Version.correct?(version_str)
      end

      sig { override.params(version: VersionParameter).void }
      def initialize(version)
        @wordpress_version = T.let(version.to_s, String)

        normalized = version.to_s.downcase
        if normalized.include?("-")
          base, prerelease = normalized.split("-", 2)
          segments = T.must(base).split(".")
          segments << "0" while segments.length < 3
          prerelease = T.must(prerelease).gsub(/([a-zA-Z])(\d)/, '\1.\2')
          normalized = "#{segments.join('.')}.#{prerelease}"
        end

        super(normalized)
      end

      sig { override.returns(String) }
      def to_semver
        @wordpress_version
      end
    end
  end
end

Dependabot::Utils.register_version_class("wordpress", Dependabot::Wordpress::Version)
