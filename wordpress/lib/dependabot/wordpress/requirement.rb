# typed: strict
# frozen_string_literal: true

require "dependabot/requirement"
require "dependabot/utils"
require "dependabot/wordpress/version"

module Dependabot
  module Wordpress
    class Requirement < Dependabot::Requirement
      extend T::Sig

      sig do
        override
          .params(requirement_string: T.nilable(String))
          .returns(T::Array[Dependabot::Requirement])
      end
      def self.requirements_array(requirement_string)
        [new(requirement_string)]
      end

      sig { params(requirements: T.untyped).void }
      def initialize(*requirements)
        requirements = requirements.flatten.compact
        requirements << ">= 0" if requirements.empty?
        super(requirements)
      end
    end
  end
end

Dependabot::Utils.register_requirement_class("wordpress", Dependabot::Wordpress::Requirement)
