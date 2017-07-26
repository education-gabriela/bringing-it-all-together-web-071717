require_relative "../config/environment.rb"

class Dog
  attr_accessor :id, :name, :breed
  FIELDS = [:id, :name, :breed]

  def initialize(args)
    @id = nil
    args.each {|key, value| self.send("#{key}=", value)}
  end

  def save
    if self.id
      self.update
    else
      sql = "INSERT INTO dogs(name, breed) VALUES (?, ?)"
      DB[:conn].execute(sql, self.name, self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs").first.first
    end
    self
  end

  def update
    sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
    DB[:conn].prepare(sql).execute(self.name, self.breed, self.id)
  end

  def self.create(args)
    dog = self.new(args)
    dog.save
  end

  def self.find_by_id(id)
    sql = "SELECT * FROM dogs WHERE id = ? LIMIT 1"
    result = DB[:conn].execute(sql, id)
    self.new_from_db(result.first)
  end

  def self.find_or_create_by(args)
    sql = "SELECT * FROM dogs WHERE name = ? AND breed = ? LIMIT 1"
    result = DB[:conn].execute(sql, args[:name], args[:breed])

    !result.empty? ? self.new_from_db(result.first) : self.create(args)
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM dogs WHERE name = ? LIMIT 1"
    result = DB[:conn].execute(sql, name)
    self.new_from_db(result.first)
  end

  def self.new_from_db(row)
    dog_hash = Hash[row.map.with_index { |row_column, i|
      [FIELDS[i], row_column]
    }]

    self.new(dog_hash)
  end

  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      )
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    DB[:conn].execute("DROP TABLE dogs")
  end
end