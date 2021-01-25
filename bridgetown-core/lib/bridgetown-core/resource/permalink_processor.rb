# frozen_string_literal: true

module Bridgetown
  module Resource
    class PermalinkProcessor
      attr_accessor :resource
      attr_accessor :slugify_mode

      def self.placeholder_processors
        @placeholder_processors || {}
      end

      def self.register_placeholder(key, block)
        @placeholder_processors ||= {}
        @placeholder_processors[key] = block
      end

      def initialize(resource)
        @resource = resource
        @slugify_mode = @resource.site.config.default_slugify_mode
      end

      def final_ext
        resource.destination.final_ext
      end

      def transform
        permalink = resource.data.permalink ||
          resource.site.config.style_to_permalink(resource.site.config.permalink)
        url_segments = permalink.chomp(".*").split("/")
        new_url = url_segments.map do |segment|
          segment.starts_with?(":") ? process_segment(segment.sub(%r{^:}, "")) : segment
        end.select(&:present?).join("/")

        if permalink.ends_with?(".*")
          "/#{new_url}#{final_ext}"
        elsif permalink.ends_with?("/")
          "/#{new_url}/"
        else
          "/#{new_url}"
        end
      end

      def process_segment(segment)
        segment = segment.to_sym
        if self.class.placeholder_processors[segment]
          segment_value = self.class.placeholder_processors[segment].(resource)
          if segment_value.is_a?(Hash)
            segment_value[:raw_value]
          else
            Utils.slugify(
              segment_value,
              mode: slugify_mode
            )
          end
        else
          segment
        end
      end

      ### Default Placeholders Processors

      register_placeholder :path, ->(resource) do
        { raw_value: resource.relative_path_basename_without_prefix }
      end

      register_placeholder :name, ->(resource) do
        resource.basename_without_ext
      end

      register_placeholder :slug, ->(resource) do
        resource.data.slug || placeholder_processors[:name].(resource)
      end

      register_placeholder :title, ->(resource) do
        resource.data.title || placeholder_processors[:slug].(resource)
      end

      register_placeholder :locale, ->(resource) do
        locale_data = resource.data.locale
        resource.site.config.available_locales.include?(locale_data) ? locale_data : nil
      end
      register_placeholder :lang, placeholder_processors[:locale]

      register_placeholder :collection, ->(resource) do
        resource.collection.label
      end

      register_placeholder :categories, ->(resource) do
        resource.taxonomies[:category].map(&:name).uniq.join("/")
      end

      # YYYY
      register_placeholder :year, ->(resource) do
        resource.date.strftime("%Y")
      end

      # MM: 01..12
      register_placeholder :month, ->(resource) do
        resource.date.strftime("%m")
      end

      # DD: 01..31
      register_placeholder :day, ->(resource) do
        resource.date.strftime("%d")
      end

      # D: 1..31
      register_placeholder :i_day, ->(resource) do
        resource.date.strftime("%-d")
      end

      # M: 1..12
      register_placeholder :i_month, ->(resource) do
        resource.date.strftime("%-m")
      end

      # YY: 00..99
      register_placeholder :short_year, ->(resource) do
        resource.date.strftime("%y")
      end
    end
  end
end