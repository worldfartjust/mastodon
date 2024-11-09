# frozen_string_literal: true

class ReportFilter
  KEYS = %i(
    status
    account_id
    target_account_id
    by_target_domain
    by_domain
    target_origin
    category
  ).freeze

  attr_reader :params

  def initialize(params)
    @params = params
  end

  def results
    scope = Report.unresolved

    relevant_params.each do |key, value|
      scope = scope.merge scope_for(key, value.to_s.strip) if value.present?
    end

    scope
  end

  private

  def relevant_params
    params.tap do |args|
      args.delete(:target_origin) if origin_is_remote_and_domain_present?
    end
  end

  def origin_is_remote_and_domain_present?
    params[:target_origin] == 'remote' && params[:by_target_domain].present?
  end

  def scope_for(key, value)
    case key.to_sym
    when :by_target_domain
      Report.where(target_account: Account.where(domain: value))
    when :by_domain
      Report.where(account: Account.where(domain: value))
    when :status
      status_scope(value)
    when :category
      Report.where(category: value)
    when :account_id
      Report.where(account_id: value)
    when :target_account_id
      Report.where(target_account_id: value)
    when :target_origin
      target_origin_scope(value)
    else
      raise Mastodon::InvalidParameterError, "Unknown filter: #{key}"
    end
  end

  def target_origin_scope(value)
    case value
    when 'local'
      Report.where(target_account: Account.local)
    when 'remote'
      Report.where(target_account: Account.remote)
    else
      raise Mastodon::InvalidParameterError, "Unknown value: #{value}"
    end
  end

  def status_scope(value)
    case value
    when 'resolved'
      Report.resolved
    else
      Report.unresolved
    end
  end
end
