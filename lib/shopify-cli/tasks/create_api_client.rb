require "shopify_cli"

module ShopifyCli
  module Tasks
    class CreateApiClient < ShopifyCli::Task
      VALID_APP_TYPES = %w(public custom)
      DEFAULT_APP_URL = "https://shopify.github.io/shopify-app-cli/help/start-app/"

      def call(ctx, org_id:, title:, type:)
        resp = ShopifyCli::PartnersAPI.query(
          ctx,
          "create_app",
          org: org_id.to_i,
          title: title,
          type: type,
          app_url: DEFAULT_APP_URL,
          redir: [OAuth::REDIRECT_HOST]
        )

        unless resp
          ctx.abort("Error - empty response")
        end

        errors = resp.dig("errors")
        if !errors.nil? && errors.any?
          ctx.abort(errors.map { |err| "#{err["field"]} #{err["message"]}" }.join(", "))
        end

        user_errors = resp.dig("data", "appCreate", "userErrors")
        if !user_errors.nil? && user_errors.any?
          ctx.abort(user_errors.map { |err| "#{err["field"]} #{err["message"]}" }.join(", "))
        end

        ShopifyCli::Core::Monorail.metadata[:api_key] = resp.dig("data", "appCreate", "app", "apiKey")

        resp.dig("data", "appCreate", "app")
      end
    end
  end
end
