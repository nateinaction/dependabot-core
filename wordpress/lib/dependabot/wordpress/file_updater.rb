# typed: strict
# frozen_string_literal: true

require "dependabot/file_updaters"
require "dependabot/file_updaters/base"

module Dependabot
  module Wordpress
    class FileUpdater < Dependabot::FileUpdaters::Base
      extend T::Sig

      VERSION_HEADER_REGEX = /^([ \t\/*#@]*Version\s*:\s*).+/i

      sig { override.returns(T::Array[Dependabot::DependencyFile]) }
      def updated_dependency_files
        updated_files = T.let([], T::Array[Dependabot::DependencyFile])

        dependencies.each do |dep|
          dep.requirements.each do |req|
            file = dependency_files.find { |f| f.name == req[:file] }
            next unless file

            previous_req = T.must(dep.previous_requirements).find { |r| r[:file] == req[:file] }
            next unless previous_req
            next if req[:requirement] == previous_req[:requirement]

            updated_content = update_version_header(
              T.must(file.content),
              T.must(previous_req[:requirement]).to_s,
              req[:requirement].to_s
            )
            next if updated_content == file.content

            updated_files << updated_file(file: file, content: updated_content)
          end
        end

        raise "No files changed!" if updated_files.none?

        updated_files
      end

      private

      sig { override.void }
      def check_required_files
        return if dependency_files.any?

        raise "No WordPress plugin or theme files found!"
      end

      sig { params(content: String, old_version: String, new_version: String).returns(String) }
      def update_version_header(content, old_version, new_version)
        content.gsub(VERSION_HEADER_REGEX) do |match|
          match.sub(old_version, new_version)
        end
      end
    end
  end
end

Dependabot::FileUpdaters.register("wordpress", Dependabot::Wordpress::FileUpdater)
