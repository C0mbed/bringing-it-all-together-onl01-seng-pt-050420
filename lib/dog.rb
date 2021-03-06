class Dog

    attr_accessor :name, :breed, :id

    def initialize(key, id=nil)
        @name = key[:name]
        @breed = key[:breed]
        @id = id
    end

    def self.create_table
        sql =  <<-SQL
            CREATE TABLE IF NOT EXISTS dogs (
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
                )
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = "DROP TABLE dogs"
        DB[:conn].execute(sql)
    end

    def save
        if self.id
            self.update
        else
            sql = <<-SQL
                INSERT INTO dogs (name, breed)
                VALUES (?, ?)
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    def self.create(key)
        dog = Dog.new(key)
        dog.save
    end

    def self.new_from_db(data)
        key = {:name => data[1], :breed => data[2]}
        Dog.new(key, data[0])
    end

    def self.find_by_id(id)
        sql = "SELECT * FROM dogs WHERE id = ?"
        result = DB[:conn].execute(sql, id)[0]
        key = {:name => result[1], :breed => result[2]}
        Dog.new(key, result[0])
    end

    def self.find_or_create_by(name:, breed:)
        dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
        if !dog.empty?
          dog_data = dog[0]
          key = {:name => dog_data[1], :breed => dog_data[2]}
          dog = Dog.new(key, dog_data[0])
        else
          key = {name: name, breed: breed}
          dog = self.create(key)
        end
        dog
    end


    def self.find_by_name(name)
        sql = <<-SQL
          SELECT *
          FROM dogs
          WHERE name = ?
          LIMIT 1
        SQL
    
       array =  DB[:conn].execute(sql,name)
        array.map do |row|
          self.new_from_db(row)
        end.first
      end

    #def self.find_by_name(name)
    #    sql = "SELECT * FROM dogs WHERE name = ? LIMIT 1;"
    #    result = DB[:conn].execute(sql, name)[0]
    #    key = {:name => result[1], :breed => result[2]}
    #    binding.pry
    #    Dog.new(key, result[0])
    #end

    def update
        dog = Dog.find_by_name(self.name)
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

end 