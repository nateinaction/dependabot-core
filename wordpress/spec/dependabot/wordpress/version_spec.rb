# typed: false
# frozen_string_literal: true

require "spec_helper"
require "dependabot/wordpress/version"

RSpec.describe Dependabot::Wordpress::Version do
  describe ".correct?" do
    it "returns true for standard versions" do
      expect(described_class.correct?("1.0.0")).to be(true)
      expect(described_class.correct?("5.3")).to be(true)
      expect(described_class.correct?("2")).to be(true)
    end

    it "returns true for pre-release versions" do
      expect(described_class.correct?("5.2.1-beta1")).to be(true)
      expect(described_class.correct?("6.0-RC2")).to be(true)
    end

    it "returns false for invalid versions" do
      expect(described_class.correct?("not-a-version")).to be(false)
      expect(described_class.correct?("")).to be(false)
    end
  end

  describe "comparison" do
    it "compares standard versions" do
      expect(described_class.new("5.3.3")).to be > described_class.new("5.3")
      expect(described_class.new("2.0.0")).to be > described_class.new("1.9.9")
      expect(described_class.new("1.0.0")).to eq(described_class.new("1.0.0"))
    end

    it "handles pre-release versions" do
      expect(described_class.new("5.3")).to be > described_class.new("5.3-beta1")
      expect(described_class.new("5.3-RC2")).to be > described_class.new("5.3-beta1")
    end
  end

  describe "#to_semver" do
    it "returns the original version string" do
      expect(described_class.new("5.3.3").to_semver).to eq("5.3.3")
      expect(described_class.new("5.3-beta1").to_semver).to eq("5.3-beta1")
    end
  end
end
