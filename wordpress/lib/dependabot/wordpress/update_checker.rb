# typed: strict
# frozen_string_literal: true

require "json"
require "excon"
require "dependabot/update_checkers"
require "dependabot/update_checkers/base"
require "dependabot/wordpress/version"

module Dependabot
  module Wordpress
    class UpdateChecker < Dependabot::UpdateCheckers::Base
      extend T::Sig

      DEFAULT_API_URL = "https://api.wordpress.org"

      sig { override.returns(T.nilable(T.any(String, Gem::Version))) }
      def latest_version
        @latest_version ||= T.let(fetch_latest_version, T.nilable(T.any(String, Gem::Version)))
      end

      sig { override.returns(T.nilable(T.any(String, Gem::Version))) }
      def latest_resolvable_version
        latest_version
      end

      sig { override.returns(T.nilable(String)) }
      def latest_resolvable_version_with_no_unlock
        dependency.version
      end

      sig { override.returns(T::Array[Dependabot::DependencyRequirement]) }
      def updated_requirements
        return dependency.requirements unless latest_version

        updated_reqs = dependency.requirements.map do |req|
          req.dup.merge(requirement: latest_version.to_s)
        end
        wrap_requirements(updated_reqs)
      end

      private

      sig { override.returns(T::Boolean) }
      def latest_version_resolvable_with_full_unlock?
        false
      end

      sig { override.returns(T::Array[Dependabot::Dependency]) }
      def updated_dependencies_after_full_unlock
        []
      end

      sig { returns(T.nilable(Gem::Version)) }
      def fetch_latest_version
        return version_class.new(dependency.version) if custom_update_uri?

        api_response = fetch_api_info
        return nil unless api_response

        latest = api_response["version"]
        return nil unless latest

        version_class.new(latest)
      end

      sig { returns(T.nilable(T::Hash[String, T.untyped])) }
      def fetch_api_info
        url = api_url_for_dependency
        response = Excon.get(
          url,
          idempotent: true,
          middlewares: Excon.defaults[:middlewares] + [Excon::Middleware::RedirectFollower]
        )

        return nil unless response.status == 200

        parsed = JSON.parse(response.body)
        return nil unless parsed.is_a?(Hash)
        return nil if parsed["error"]

        parsed
      rescue JSON::ParserError, Excon::Error
        nil
      end

      sig { returns(String) }
      def api_url_for_dependency
        base_url = options.fetch(:update_source, DEFAULT_API_URL).to_s
        slug = dependency.name
        dep_type = dependency_type

        if dep_type == :theme
          "#{base_url}/themes/info/1.2/" \
            "?action=theme_information" \
            "&request[slug]=#{slug}" \
            "&request[fields][versions]=1"
        else
          "#{base_url}/plugins/info/1.2/" \
            "?action=plugin_information" \
            "&request[slug]=#{slug}" \
            "&request[fields][versions]=1"
        end
      end

      sig { returns(Symbol) }
      def dependency_type
        req = dependency.requirements.first
        return :plugin unless req

        source = req[:source]
        return :plugin unless source.is_a?(Hash)

        source[:type] == :theme ? :theme : :plugin
      end

      sig { returns(T::Boolean) }
      def custom_update_uri?
        dependency.requirements.any? do |req|
          meta = dependency.metadata
          next false unless meta.is_a?(Hash)

          update_uri = meta[:update_uri]
          next false if update_uri.nil? || update_uri.to_s.empty?

          uri = update_uri.to_s.strip.downcase
          !uri.start_with?("https://api.wordpress.org") && !uri.match?(%r{\Aw\.org/})
        end
      end
    end
  end
end

Dependabot::UpdateCheckers.register("wordpress", Dependabot::Wordpress::UpdateChecker)
