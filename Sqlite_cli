require './My_Sqlite'
require "readline"

class Sqlite_cli
    def initialize
        @is_select = false
        @is_delete = false
        @is_update = false
        @is_insert = false
        @commands = nil
        @runner = MySqliteRequest.new
    end
    def cleaner(str)
        str = str.gsub(/,/, ' ')
        str = str.gsub(/\(/, ' ')
        str = str.gsub(/\)/, ' ')
        str = str.gsub(/;/, '')
        @commands = str.split
    end
    def like(src, temp)
        return (src.downcase == temp.downcase) ? true : false
    end

    def set_command()
        com = @commands[0]
        if like(com, 'select')
            @is_select = true
        elsif like(com, 'delete')
            @runner.delete
            @is_delete = true
        elsif like(com, 'update')
            @is_update = true
        elsif like(com, 'insert')
            @is_insert = true
        else
            puts "Command not found #{com}".red
            exit(false)
        end
    end

    def do_select()
        sel = []
        for i in 1..@commands.length do
            if !like(@commands[i], 'from')
                sel << @commands[i]
            else
                break
            end
        end
        if sel.length == 1
            @runner =  @runner.select(sel.join(''))
        else
            @runner = @runner.select(sel)
        end
    end
    def do_delete()
        for i in 2..@commands.length do
            com = @commands[i]
            if like(com, 'where') && i+3 <= @commands.length
                @runner = @runner.where(@commands[i+1], @commands[i+3])
                break
            end
        end
    end
    def do_insert
        for i in 1..@commands.length-1 do
            if like(@commands[i], 'into') && i+1 < @commands.length
                @runner = @runner.insert(@commands[i+1])
                break
            end
        end
        h = @commands.find_index('values')
        h += 1
        values = []

        for j in h..@commands.length-1
            values << @commands[j]
        end
        @runner = @runner.values(values)
    end
    def get_end
        for e in 3..@commands.length-1 do
            if like(@commands[e], 'where')
                return e-3
            end
        end
    end
    def array_to_hash(array)
        array.delete('=')
        hash = Hash.new
        i = 1
        while i < array.length
            hash[array[i-1]] = array[i]
            i += 2
        end
        return hash
    end
    def do_update
        if @commands.length < 5
            puts "there is little argument for update".red
            exit(false)
        end
        @runner = @runner.update(@commands[1])
        if like(@commands[2], 'set')
            temp = @commands.slice(3, get_end)
            @runner = @runner.set(array_to_hash(temp))
        end
        if like(@commands[get_end+3], 'where') && get_end+6 <= @commands.length
            @runner = @runner.where(@commands[get_end+4], @commands[get_end+6])
        end
    end
    def call_from()
        if @is_select || @is_delete
            for i in 1..@commands.length-1 do
                if like(@commands[i], 'from') && i+1 < @commands.length
                    @runner = @runner.from(@commands[i+1])
                    break
                end
            end
        end
    end

    def go
        if @is_select
            do_select
            call_from
        elsif @is_delete
            do_delete
            call_from
        elsif @is_insert
            do_insert
        elsif @is_update
            do_update
        else
            puts "command not found"
        end
        @runner.run
    end

end

puts "MySQLite version 0.1 2022-11-18"
while buf = Readline.readline("my_sqlite_cli> ", true)
    if buf == 'quit'
        exit(true)
    end
    # Sqlite cli start here
    cli = Sqlite_cli.new
    buf = cli.cleaner(buf)
    cli.set_command
    cli.go
end
