class Pups::ExecCommand < Pups::Command
  attr_reader :commands, :cd
  attr_accessor :background, :raise_on_fail, :stdin

  def self.from_hash(hash, params)
    cmd = new(params, hash["cd"])

    case c = hash["cmd"]
    when String then cmd.add(c)
    when Array then c.each{|i| cmd.add(i)}
    end

    cmd.background = hash["background"]
    cmd.raise_on_fail = hash["raise_on_fail"] if hash.key? "raise_on_fail"
    cmd.stdin = hash["stdin"]

    cmd
  end

  def self.from_str(str, params)
    cmd = new(params)
    cmd.add(str)
    cmd
  end

  def initialize(params, cd = nil)
    @commands = []
    @params = params
    @cd = interpolate_params(cd)
    @raise_on_fail = true
  end

  def add(cmd)
    @commands << process_params(cmd)
  end

  def run
    commands.each do |command|
      Pups.log.info("> #{command}")

      pid = spawn(command)


      Pups.log.info(@result.readlines.join("\n")) if @result
    end
  rescue
    raise if @raise_on_fail
  end

  def spawn(command)
    if background
      pid = Process.spawn(command)
      Thread.new do
        Process.wait(pid)
      end
      return
    end

    IO.popen(command, "w+") do |f|
      if stdin
        # need a way to get stdout without blocking
        Pups.log.info(stdin)
        f.write stdin
        f.close
      else
        Pups.log.info(f.readlines.join)
      end
    end

    raise RuntimeError.new("Failed with return #{$?.inspect}") unless $? == 0

    nil

  end


end
