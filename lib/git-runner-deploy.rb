require 'digest'

module GitRunner
  class Instruction
    class Base
    end

    # Performs deployments using capistrano (cap deploy)
    class Deploy < Base
      VERSION = '0.1.0'

      attr_accessor :clone_directory


      def should_run?
        branches.empty? || branches.include?(branch.name)
      end

      def perform
        start_time = Time.now

        Text.out(Text.green("Performing Deploy (#{environment_from_branch(branch)})"), :heading)

        checkout_branch
        ensure_presence_of_capfile
        prepare_deploy_environment
        perform_deploy
        cleanup_deploy_environment

        end_time = Time.now

        Text.out(Text.green("\u2714 Deploy successful, completed in #{(end_time - start_time).ceil} seconds"))
      end


    private
      def branches
        args.split(/\s+/)
      end

      def ensure_presence_of_capfile
        unless File.exists?("#{clone_directory}/Capfile")
          Text.out(Text.red("Missing Capfile, unable to complete deploy."))
          fail!
        end
      end

      def uses_bundler?
        File.exists?("#{clone_directory}/Gemfile")
      end

      def multistage?
        result = execute("grep -e 'require.*capistrano.*multistage' #{clone_directory}/#{Configuration.instruction_file} || true")
        !result.empty?
      end

      def checkout_branch
        timestamp            = Time.now.strftime("%Y%m%d%H%M%S")
        self.clone_directory = File.join(Configuration.tmp_directory, "#{branch.repository_name}-#{environment_from_branch(branch)}-#{timestamp}")

        Text.out("Checking out #{branch.name} to #{clone_directory}")

        execute(
          "mkdir -p #{clone_directory}",
          "git clone --depth=1 --branch=#{branch.name} file://#{branch.repository_path} #{clone_directory}"
        )
      end

      def prepare_deploy_environment
        Text.out("Preparing deploy environment")

        if uses_bundler?
          execute(
            "cd #{clone_directory}",
            "bundle install --path=#{File.join(Configuration.tmp_directory, '.gems')}"
          )
        end
      end

      def perform_deploy
        cap_deploy_command = if multistage?
          Text.out("Deploying application (multistage detected)")
          "cap #{environment_from_branch(branch)} deploy"
        else
          Text.out("Deploying application")
          "cap deploy"
        end

        Text.indent do
          execute(
            "cd #{clone_directory}",
            cap_deploy_command,
            :errproc => method(:cap_deploy_outproc)
          )
        end
      end

      def cap_deploy_outproc(out)
        if out =~ /executing `(.*)'/
          case $1
          when 'bundle:install'
            Text.out('* Installing gems')

          when 'deploy:restart'
            Text.out('* Restarting application')
          end
        end
      end

      def cleanup_deploy_environment
        Text.out("Cleaning deploy environment")
        execute(
          "rm -rf #{clone_directory}",
          "cd #{branch.repository_path}"
        )
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
