test_name 'blocking os fact does not block oss fact' do
  tag 'risk:high'

  require 'facter/acceptance/user_fact_utils'
  extend Facter::Acceptance::UserFactUtils

  custom_fact_file = 'custom_facts.rb'
  custom_fact_name = "oss"
  custom_fact_value = "custom_fact_value"

  fact_content = <<-CUSTOM_FACT
  Facter.add(:#{custom_fact_name}) do
    setcode do
      "#{custom_fact_value}"
    end
  end
  CUSTOM_FACT

  config_data = <<~FACTER_CONF
    facts : {
      blocklist : [ "os" ],
    }
  FACTER_CONF

  agents.each do |agent|
    fact_dir = agent.tmpdir('custom_facts')
    fact_file = File.join(fact_dir, custom_fact_file)

    config_dir = get_default_fact_dir(agent['platform'], on(agent, facter('kernelmajversion')).stdout.chomp.to_f)
    config_file = File.join(config_dir, 'facter.conf')

    agent.mkdir_p(config_dir)
    create_remote_file(agent, fact_file, fact_content)
    create_remote_file(agent, config_file, config_data)

    teardown do
      agent.rm_rf(fact_dir)
      agent.rm_rf(config_dir)
    end

    step "Facter: Verify that the blocked fact is not displayed" do
      on(agent, facter("os")) do |facter_output|
        assert_equal("", facter_output.stdout.chomp)
      end
    end

    step "Facter: Verify that the custom fact is displayed" do
      on(agent, facter("--custom-dir=#{fact_dir} oss")) do |facter_output|
        assert_match(/#{custom_fact_value}/, facter_output.stdout.chomp)
      end
    end
  end
end
