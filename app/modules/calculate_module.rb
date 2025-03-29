module CalculateModule
  def sum(a, b)
    return a + b
  end

  def calculate_age(age)
    if age < 18
      "You are a minor."
    elsif age >= 18 && age < 65
      "You are an adult."
    else
      "You are a senior citizen."
    end
  end
end
