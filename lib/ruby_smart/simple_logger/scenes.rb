# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Scenes
      def self.included(base)
        # debug method
        # log level @ debug
        # prints: prettified data by using the 'inspect' method
        #
        # > ================================================= [Debug] ================================================
        # > "DEBUGGED DATA" <- analyzed by awesome_print#ai method
        # > ==========================================================================================================
        base.scene :debug, { level: :debug, inspect: true, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] } do |data, *args|
          subject, opts = _scene_subject_with_opts(args, 'Debug')
          self.log data, _scene_opt(:debug, { subject: subject }, opts)
        end

        # info method (BASE)
        # log level @ info
        # prints: enclosed data
        #
        # > ================================================= [Info] =================================================
        # > DATA
        # > ==========================================================================================================
        base.scene :info, { level: :info, mask: { clr: :cyan }, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] } do |data, *args|
          subject, opts = _scene_subject_with_opts(args, 'Info')
          self.log data, _scene_opt(:info, { subject: subject }, opts)
        end

        # warn method (BASE)
        # log level @ warn
        # prints: enclosed data
        #
        # > ================================================= [Warn] =================================================
        # > DATA
        # > ==========================================================================================================
        base.scene :warn, { level: :warn, mask: { clr: :yellow }, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] } do |data, *args|
          subject, opts = _scene_subject_with_opts(args, 'Warn')
          self.log data, _scene_opt(:warn, { subject: subject }, opts)
        end

        # error method (BASE)
        # log level @ error
        # prints: enclosed data
        #
        # > ================================================ [Error] =================================================
        # > DATA
        # > ==========================================================================================================
        base.scene :error, { level: :error, mask: { clr: :red }, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] } do |data, *args|
          subject, opts = _scene_subject_with_opts(args, 'Error')
          self.log data, _scene_opt(:error, { subject: subject }, opts)
        end

        # fatal method (BASE)
        # log level @ fatal
        # prints: enclosed data
        #
        # > ================================================ [Fatal] =================================================
        # > DATA
        # > ==========================================================================================================
        base.scene :fatal, { level: :fatal, mask: { clr: :bg_red }, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] } do |data, *args|
          subject, opts = _scene_subject_with_opts(args, 'Fatal')
          self.log data, _scene_opt(:fatal, { subject: subject }, opts)
        end

        # unknown method (BASE)
        # log level @ unknown
        # prints: enclosed data
        #
        # > =============================================== [Unknown] ================================================
        # > DATA
        # > ==========================================================================================================
        base.scene :unknown, { level: :unknown, mask: { clr: :gray }, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] } do |data, *args|
          subject, opts = _scene_subject_with_opts(args, 'Unknown')
          self.log data, _scene_opt(:unknown, { subject: subject }, opts)
        end

        # success method
        # log level @ success (sub-level of info)
        # prints: enclosed data
        #
        # > ================================================ [Success] ================================================
        # > DATA
        # > ===========================================================================================================
        base.scene :success, { level: :success, mask: { clr: :green }, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] } do |data, *args|
          subject, opts = _scene_subject_with_opts(args, 'Success')
          self.log data, _scene_opt(:success, { subject: subject }, opts)
        end

        # header method
        # log level @ debug
        # prints: prettified subject
        #
        # > ===========================================================================================================
        # > ================================================ <Subject> ================================================
        # > ===========================================================================================================
        base.scene :header, { level: :debug, payload: [:mask, [:mask, ' <%{subject}> '], :mask] } do |subject, opts = {}|
          # autostart a timer method, if required
          self.timer(:start, :default) if opts[:timer]

          self.log nil, _scene_opt(:header, { subject: subject }, opts)
        end

        # footer method
        # log level @ debug
        # prints: prettified subject
        #
        # > ===========================================================================================================
        # > ================================================ >Subject< ================================================
        # > ===========================================================================================================
        base.scene :footer, { level: :debug, payload: [:mask, [:mask, ' >%{subject}< '], :mask] } do |subject, opts = {}|
          self.log nil, _scene_opt(:footer, { subject: subject }, opts)

          # clears & prints timer
          self.desc("duration: #{self.timer(:clear, :default, :humanized => true)}") if opts[:timer]
        end

        # topic method
        # log level @ debug
        # prints: prettified subject
        #
        # > --------------------------------------------------------------------------------
        # > #----------------------------------- Subject ----------------------------------#
        # > --------------------------------------------------------------------------------
        base.scene :topic, { level: :debug, mask: { char: '-', length: 95, clr: :blueish }, payload: [:mask, [:mask, '%{title}'], :mask] } do |subject, opts = {}|
          opts         = _scene_opt(:topic, opts)
          txt          = " #{subject} ".center(opts[:mask][:length] - 2, opts[:mask][:char])
          opts[:title] = "##{txt}#"

          self.log nil, opts
        end

        # theme method
        # log level @ debug
        # prints: prettified, colored subject
        #
        # > # Subject
        # > ----------------------------------------------------------------------
        base.scene :theme, { level: :debug, clr: :purple, mask: { char: '-', length: 85, clr: :purple }, payload: [[:txt, '# %{subject}'], :mask] } do |subject, opts = {}|
          self.log nil, _scene_opt(:theme, { subject: subject }, opts)
        end

        # theme_result method
        # log level @ debug
        # prints: prettified, colored result
        #
        # > ----------------------------------------------------------------------
        # > -> Result
        # >
        base.scene :theme_result, { level: :debug, mask: { char: '-', length: 85, clr: :purple }, payload: [:mask, [:txt, '-> %{result}'], ''] } do |result, status = nil, opts = {}|
          res_or_clr = status.nil? ? result : status
          self.log nil, _scene_opt(:theme_result, { result: result, clr: _res_clr(res_or_clr) }, opts)
        end

        # theme_line method
        # log level @ debug
        # prints: colored line with no text
        #
        # > ----------------------------------------------------------------------
        base.scene :theme_line, { level: :debug, mask: { char: '-', length: 85, clr: :purple }, payload: [:mask] } do |opts = {}|
          self.log nil, _scene_opt(:theme_line, opts)
        end

        # desc method
        # log level @ debug
        # prints: colored text
        #
        # > "description"
        # >
        base.scene :desc, { level: :debug, clr: :purple, payload: [[:txt, '%{description}']] } do |description, opts = {}|
          self.log nil, _scene_opt(:desc, { description: description.to_s }, opts)
        end

        # job method
        # log level @ debug
        # prints: colored line with job name (on inline formatter it prevents a line-break)
        # calls the result method if a block was provided
        #
        # > - Job name                                                         =>
        #     ________________________________________________________________ <- 64 chars
        base.scene :job, { level: :debug, clr: :cyan, nl: false, length: 64, payload: [[:concat, ['- ', [:txt, '%{name}'], ' => ']]] } do |name, opts = {}, &block|
          self.log nil, _scene_opt(:job, { name: name }, opts)
          self.result(*block.call) if block_given?
        end

        # sub_job method
        # log level @ debug
        # prints: line with job name (on inline formatter it prevents a line-break)
        # calls the result method if a block was provided
        #
        # >   * Subjob name                                                    =>
        #       ______________________________________________________________ <- 62 chars
        base.scene :sub_job, { level: :debug, clr: :cyan, nl: false, length: 62, payload: [[:concat, ['  * ', [:txt, '%{name}'], ' => ']]] } do |name, opts = {}, &block|
          self.log nil, _scene_opt(:sub_job, { name: name }, opts)
          self.result(*block.call) if block_given?
        end

        # result method
        # log level @ debug
        # prints: colored result
        #
        # > Result
        base.scene :result, { level: :debug, payload: [[:txt, '%{result}']] } do |result, status = nil, opts = {}|
          res_or_clr = status.nil? ? result : status
          self.log nil, _scene_opt(:result, { result: result, clr: _res_clr(res_or_clr) }, opts)
        end

        # job_result method
        # log level @ debug
        # prints: job with combined colored result
        #
        # > - Job name                                                         => Result
        base.scene :job_result, { level: :debug } do |name, result, status = nil, opts = {}|
          self.job(name, opts)
          self.result(result, status, opts)
        end

        # sub_job_result method
        # log level @ debug
        # prints: sub_job with combined colored result
        #
        # >   * Subjob name                                                    => Result
        base.scene :sub_job_result, { level: :debug } do |name, result, status = nil, opts = {}|
          self.sub_job(name, opts)
          self.result(result, status, opts)
        end

        # line method
        # log level @ debug
        # prints: just a line with data
        #
        # > DATA
        base.scene :line, { level: :debug } do |data, opts = {}|
          self.log data, _scene_opt(:line, opts)
        end

        # print method
        # log level @ debug
        # prints: prints data without a newline
        #
        # > DATA
        base.scene :print, { level: :debug, nl: false } do |data, opts = {}|
          self.log data, _scene_opt(:print, opts)
        end

        # nl method
        # log level @ debug
        # prints: a line break without any data
        #
        # >
        # >
        base.scene :nl, { level: :debug } do |opts = {}|
          self.log '', _scene_opt(:nl, opts)
        end

        # spec method
        # log level @ debug
        # prints: colored spec result string - depending on the status (on inline formatter it prevents a line-break)
        #
        # true      => . (green)
        # false     => F (red)
        # "other"   => ? (yellow)
        #
        # > .FFF...??...F....F...F..???....F...??
        base.scene :spec, { level: :debug, nl: false, payload: [[:txt, '%{result}']] } do |status, opts = {}|
          result = if status.is_a?(TrueClass)
                     '.'
                   elsif status.is_a?(FalseClass)
                     'F'
                   else
                     status = :yellow
                     '?'
                   end
          self.log nil, _scene_opt(:spec, { result: result, clr: _res_clr(status) }, opts)
        end

        # progress method
        # log level @ debug
        # prints: a colored progress indicator
        #
        # > - Progress of Step 0                               [  0%] >-------------------------------------------------
        # > - Progress of Step 1                               [ 40%] ===================>------------------------------
        #     ________________________________________________ <- 48 chars
        #                                                 50 chars -> __________________________________________________
        base.scene :progress, { level: :debug, payload: [[:txt, '- %{name} [%{perc}%] %{progress}']] } do |name, perc, opts = {}|
          pmask_length = 50

          # convert and fix progress
          perc = perc.to_i
          perc = 0 if perc < 0
          perc = 100 if perc > 100

          pmask_left_length  = (pmask_length * perc / 100)
          # reduce 1 char for the arrow '>'
          pmask_left_length  -= 1 if pmask_left_length > 0
          pmask_right_length = pmask_length - pmask_left_length - 1

          progress_string = _clr(('=' * pmask_left_length) + '>', :green) + _clr('-' * pmask_right_length, :red)
          perc_string     = perc.to_s.rjust(3, ' ')
          self.log nil, _scene_opt(:progress, { name: _clr(_lgth(name, 48), :cyan), perc: perc_string, progress: progress_string }, opts)
        end

        # processed method
        # log level @ debug
        # prints: a processed output with unicode box-chars (e.g. ║ )
        #
        # ╔ START ❯ job
        # ╟ doing some cool log
        # ╟ doing some extra log
        # ╚ END   ❯ job [SUCCESS] (duration: 4.34223)
        base.scene :processed, { level: :debug } do |name, opts = {}, &block|
          # increase level
          lvl = processed_lvl(:up)

          # resolve a new time-key.
          # The key depends on the current level - this should be possible, since processes on the same level should not be possible
          timer_key = if opts[:timer]
                        "processed_#{lvl}"
                      else
                        nil
                      end

          begin
            # starts new time (if key was created)
            self.timer(:start, timer_key)

            # send START name as +data+ - the full log line is created through the +_pcd+ method.
            self.log(name, _scene_opt(:processed, opts, { pcd: :start }))

            # run the provided block and resolve result
            result_str = case block.call
                         when true
                           '[SUCCESS]'.bg_green + ' '
                         when false
                           '[FAIL]'.bg_red + ' '
                         else
                           ''
                         end
          rescue => e
            self.fatal("#{e.message} @ #{e.backtrace_locations&.first}") unless opts[:silent]
            # reraise exception
            raise
          ensure
            result_str ||= ''

            # send END name with result & possible time as +data+ - the full log line is created through the +_pcd+ method.
            self.log("#{name} #{result_str}#{(timer_key ? "(#{self.timer(:clear, timer_key, humanized: true)})" : '')}", _scene_opt(:processed, opts, { pcd: :end }))

            # reduce level
            processed_lvl(:down)
          end

          true
        end

        # model method
        # log level @ error/success/info
        # prints: ActiveRecord::Base related data, depending on the models "save" state (also shows possible errors)
        base.scene :model do |model, opts = {}|
          # build model-logging string
          mdl_string = "#{model.id.present? ? "##{model.id} - " : ''}#{model.to_s[0..49]}"

          # resolve model's status
          status = ((model.persisted? && model.errors.empty?) ? (model.previous_changes.blank? ? :skipped : :success) : :error)

          # switch between status
          case status
          when :success
            # show verbose logging for updated records
            if opts[:verbose] != false && !model.previously_new_record?
              log(:success, "#{mdl_string} (#{model.previous_changes.inspect})", tag: "#{model.class.name.upcase}|UPDATED")
            else
              log(:success, mdl_string, tag: "#{model.class.name.upcase}|#{(model.previously_new_record? ? 'CREATED' : 'UPDATED')}")
            end
          when :error
            log(:error, "#{mdl_string} (#{model.errors.full_messages.join(', ').presence || '-'})", tag: "#{model.class.name.upcase}|ERROR")
          else
            log(:info, mdl_string, tag: "#{model.class.name.upcase}|#{status}")
          end
        end
      end
    end
  end
end
