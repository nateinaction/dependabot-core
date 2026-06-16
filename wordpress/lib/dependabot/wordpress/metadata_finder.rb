# typed: strict
# frozen_string_literal: true

require "dependabot/metadata_finders"
require "dependabot/metadata_finders/base"

module Dependabot
  module Wordpress
    class MetadataFinder < Dependabot::MetadataFinders::Base
      extend T::Sig

      sig { override.returns(T.nilable(String)) }
      def homepage_url
        dep_type = dependency.requirements.first&.dig(:source, :type)
        type_path = dep_type == :theme ? "themes" : "plugins"
        "https://wordpress.org/#{type_path}/#{dependency.name}/"
      end

      private

      sig { override.returns(T.nilable(Dependabot::Source)) }
      def look_up_source
        source_url = dependency.requirements
                               .filter_map { |r| r.dig(:source, :source_url) }
                               .first

        return Source.from_url(source_url) if source_url

        nil
      end
    end
  end
end

Dependabot::MetadataFinders.register("wordpress", Dependabot::Wordpress::MetadataFinder)
