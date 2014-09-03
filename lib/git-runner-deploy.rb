require 'digest'

module GitRunner
  class Instruction
    class Base
    end

    # Performs deployments using capistrano (cap deploy)
    class Deploy < Base
      VERSION = '0.1.5'

      attr_accessor :clone_directory


      def should_run?
        branches.empty? || branches.include?(branch.name)
      end

      def perform
        GitRunner::Hooks.fire(:deploy_begin, self)

        start_time = Time.now

        Text.out(Text.green("Performing Deploy (#{environment_from_branch(branch)})"), :heading)

        checkout_branch
        prepare_deploy_environment
        perform_deploy

        end_time = Time.now

        Text.out(Text.green("\u2714 Deploy successful, completed in #{(end_time - start_time).ceil} seconds"))


      rescue Exception => ex
        GitRunner::Hooks.fire(:deploy_failure, self)
        raise ex
      end


    private
      def default_deploy_command(branch_name)
        if multistage?
          "cap #{branch_name == 'master' ? 'production' : branch} deploy"
        else
          "cap deploy"
        end
      end

      def branches_with_commands
        b_args = args.dup

        if !b_args.empty? && b_args.scan(/\((.*?)(?:="(.*?)"?)?\)/).empty?
          # Support old format for branch declarations
          b_args = b_args.split(/\s+/).map { |a| "(#{a})" }.join
        end

        b_args.scan(/\((.*?)(?:="(.*?)"?)?\)/).inject({}) do |hash, (branch, command)|
          hash[branch] = command || default_deploy_command(branch)
          hash
        end
      end

      def branches
        branches_with_commands.keys
      end

      def uses_bundler?
        File.exists?("#{clone_directory}/Gemfile")
      end

      def multistage?
        result = execute("grep -e 'require.*capistrano.*multistage' #{clone_directory}/#{Configuration.instruction_file} || true")
        !result.empty?
      end

      def checkout_branch
        self.clone_directory = File.join(Configuration.tmp_directory, "#{branch.repository_name}")
        revision             = execute("git ls-remote file://#{branch.repository_path} #{branch.name}").split("\t")[0]

        if File.exist?(clone_directory)
          Text.out("Checking out #{branch.name} to #{clone_directory}")

          execute(
            "cd #{clone_directory}",
            "git fetch origin",
            "git fetch --tags origin",
            "git reset --hard #{revision}",
            "git clean -x -f"
          )
        else
          Text.out("Checking out #{branch.name} to #{clone_directory} (fresh clone)")

          execute(
            "mkdir -p #{clone_directory}",
            "git clone file://#{branch.repository_path} #{clone_directory}",
            "cd #{clone_directory}",
            "git checkout -b git-runner-deploy #{revision}"
          )
        end
      end

      def prepare_deploy_environment
        Text.out("Preparing deploy environment")

        if uses_bundler?
          execute(
            "cd #{clone_directory}",
            "bundle install --path=.git-runner/gems"
          )
        end
      end

      def perform_deploy
        deploy_command = branches_with_commands[branch.name] || default_deploy_command(branch.name)

        # 'bundle exec' if bundler is being used
        deploy_command = "bundle exec #{deploy_command}" if uses_bundler?

        Text.out("Deploying application (#{deploy_command})")

        Text.indent do
          execute(
            "cd #{clone_directory}",
            deploy_command,
            :errproc => method(:deploy_outproc)
          )
        end

        GitRunner::Hooks.fire(:deploy_success, self)
      end

      def deploy_outproc(out)
        if out =~ /executing `(.*)'/
          case $1
          when 'deploy:update_code'
            Text.out('* Copying application code')

          when 'bundle:install'
            Text.out('* Installing gems')

          when 'assets:precompile', 'deploy:assets:precompile'
            Text.out('* Precompilng assets')

          when 'deploy:restart'
            Text.out('* Restarting application')
          end
        end
      end

      def environment_from_branch(branch)
        if branch.name == 'master'
          'production'
        else
          branch.name
        end
      end
    end
  end
end
