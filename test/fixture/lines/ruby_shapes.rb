puts RbConfig.new.run

class RbConfig
  def run
    RB_LIMIT + rb_attempt(1)
  end

  RB_LIMIT = 3

  def rb_attempt(n)
    n
  end
end
