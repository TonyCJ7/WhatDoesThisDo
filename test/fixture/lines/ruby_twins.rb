puts RbA.new.rb_twin(1) + RbB.new.rb_twin(1)

class RbA
  def rb_twin(n)
    n
  end
end

class RbB
  def rb_twin(n)
    n + 1
  end
end
