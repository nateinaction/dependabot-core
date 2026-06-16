# typed: strong
# frozen_string_literal: true

require "dependabot/wordpress/file_fetcher"
require "dependabot/wordpress/file_parser"
require "dependabot/wordpress/update_checker"
require "dependabot/wordpress/file_updater"
require "dependabot/wordpress/metadata_finder"
require "dependabot/wordpress/version"
require "dependabot/wordpress/requirement"

require "dependabot/pull_request_creator/labeler"
Dependabot::PullRequestCreator::Labeler
  .register_label_details("wordpress", name: "wordpress", colour: "21759B")

require "dependabot/dependency"
Dependabot::Dependency.register_production_check("wordpress", ->(_) { true })
