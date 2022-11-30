require 'csv'
require 'colorize'
class String
    def numeric?
        match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/) == nil ? false : true
    end
end

class MySqliteRequest
    def initialize
        @is_select = false
        @to_select = nil
        @where_condition = []
        @is_where = false
        @is_join = false
        @is_insert = false
        @is_update = false
        @is_delete = false
        @to_delete = nil
        @update_delete_indexs = []
        @updated_rows = []
        @insert_or_update = nil
        @to_insert = nil
        @table = nil
        @selected = nil
    end    

    def from(table_name)
        if File.exist?(table_name)
            @table = CSV.parse(File.read(table_name), headers: true)
            @to_delete = table_name
        elsif File.exist?(table_name+='.csv')
            @table = CSV.parse(File.read(table_name), headers: true)
            @to_delete = table_name
        else
            puts "CSV table not found: '#{table_name}'".red
            exit(false)
        end
        return self
    end

    def select(column_name)
        # if @table == nil
        #     puts "Table not found".red
        #     return self
        # end
        @is_select = true
        @to_select = column_name
        self
    end
    def do_select
        @selected = Marshal.load(Marshal.dump(@table)) #@table.dup
        if @to_select == '*'
            return self
        end
        if @to_select.class == Array
            names = @selected.headers
            names.each do |name|
                if !@to_select.include?(name) && name!=nil
                   @selected.delete(name)
                end
            end
            @selected.to_csv
            return self
        elsif @to_select.class == String
            names = @selected.headers
            names.each do |name|
                if @to_select != name && name!=nil
                   @selected.delete(name)
                end
            end
            @selected.to_csv
            return self
        else
            puts "Selecting error: '#{@to_select.class}' doesn't support".red
            return self
        end
    end

    def is_col_exist(tab, col) 
        return (tab.headers.include?(col)) ? true : false
    end
    def where(column_name, criteria)
        @is_where = true
        @where_condition << column_name
        @where_condition << criteria
        return self
    end
    def do_where
        if @table == nil
            puts "Table not found".red
            exit(false)
        end
        if @is_update || @is_delete # should updated rows indexes
            for i in 0..@table.length-1 do
                if @table.by_row[i][@where_condition[0]] == @where_condition[1]
                    @update_delete_indexs << i
                end
            end
            return self
        end
        # select method
        result = CSV::Table.new([], headers:@table.headers.dup)
        @table.filter do |raw|
            if raw[@where_condition[0]] == @where_condition[1].to_s
                result << raw.dup
            end
        end
        if @is_select && result != nil
            temp = result.headers.dup
            temp.each do |col|
                if !is_col_exist(@selected, col)
                    result.delete(col)
                end
            end
            @selected = Marshal.load(Marshal.dump(result))
        else
            @table = result.clone
        end  
    end
    def concat(t1, t2, indexes)
        hed = t2.headers
        indexes.each{ |r, i|
            hed.each do |hh|
                if !is_col_exist(t1, hh)
                    # puts "#{hh} - #{t1.by_row[r]}"
                    t1.by_row[r][hh] = t2.by_row[i][hh]
                    # puts "#{i} - #{t1.by_row[r]}"
                end
            end
        }
        return t1
    end
    def get_match_col(table, col, val)
        for i in 0..table.length-1 do
            if table.by_row[i][col] == val
                # puts "#{i} << #{table.by_row[i]} === #{val}"
                return i
            end
        end
        nil
    end
    def join(col_a, file_b, col_b)
        @is_join = true
        newDB = CSV.parse(File.read(file_b), headers: true)
        matched = CSV::Table.new([], headers:true)
        indexes = Hash.new
        for row_in in 0..@table.length-1 do
            i = get_match_col(newDB, col_b, @table.by_row[row_in][col_a])
            if i != nil
                matched << newDB.by_row[i]
                indexes[row_in] = i
            end
        end
        @table = concat(@table, matched, indexes)
        # @table.each do |r|
        #     print r.to_hash
        # end
        # @table << newDB[column_on_db_b]
        return self
    end
    def reverse(csv, len)
        i = 0
        while i < len
            temp = csv[i]
            csv[i] = csv[len]
            csv[len] = temp
            i += 1
            len -= 1
        end
        return csv
    end

    def order(order, column_name)
        if order != 'asc' && order != 'desc'
            puts "Ordering failure: '#{order}' type is not avaiable".red
            return self
        end
        sorted = nil
        for i in 0..@table.headers.length() do
            if @table.headers[i] == column_name
                if column_name.numeric? 
                    sorted = @table.sort_by{|line| line[i].to_i}
                else
                    sorted = @table.sort_by{|line| line[i].to_s}
                end
                if order == 'desc'
                    sorted = reverse(sorted, sorted.length()-1)
                end
                @table.delete_if do |row| # delete all rows for replace sorted rows
                    true
                end
                i = 0
                sorted.each do |row| # set sort table rows 
                    @table << Marshal.load(Marshal.dump(row)) # for dublicate row
                    i += 1
                end
                return self
            end
        end
        return self
    end

    def insert(table_name)
        @is_insert = true
        if File.exist?(table_name)
            @to_insert = CSV.parse(File.read(table_name), headers: true)
        elsif File.exist?(table_name+='.csv')
            @to_insert = CSV.parse(File.read(table_name), headers: true)
        else
            puts "MySqlite; table not found: '#{table_name}'".red
            exit(false)
        end
        @insert_or_update = table_name
        return self
    end
    def writeCSV(table, to_write_csv)
        CSV.open(table, "w") do |csv|
            csv << to_write_csv.headers
            to_write_csv.each do |row|
              csv << row
            end
        end
    end
    def values(data)
        if @to_insert == nil
            puts "Cannot insert. Table not found".red
            return self
        end
        if data.class != Hash && data.class != Array
            puts "Type not support: '#{data.class.to_s.red}'"
            return self
        end
        row = nil
        if data.class == Hash
            temp = Hash.new("undefined")#Hash.new()
            @to_insert.headers.each do |key| # for set current place
                temp[key.to_sym.to_s] = data[key.to_sym]
            end
            row = CSV::Row.new(temp.keys, temp.values, headers:true)
        elsif data.class == Array
            row = CSV::Row.new(@to_insert.headers, data, headers:true)
        end
        @to_insert << row
        return self
    end

    def update(table_name)
        @is_update = true
        @insert_or_update = table_name
        if File.exist?(table_name)
            @table = CSV.parse(File.read(table_name), headers: true)
            @to_delete = table_name

        elsif File.exist?(table_name+=".csv")
            @table = CSV.parse(File.read(table_name), headers: true)
            @to_delete = table_name
        else
            puts "MySqlite; table not found: '#{table_name}'".red
            exit(false)
        end
        return self
    end

    def changeHash(hash1, hash2)
        hash2.each { |key, value|
            if hash1.has_key?(key.to_s)
                hash1[key.to_s] = value
            end
        }
        return hash1
    end
    def set(data)
        for i in 0..@table.length-1 do
                en = @table.by_row[i].to_hash
                en = changeHash(en, data)
                en = CSV::Row.new(en.keys, en.values, headers:true)
                @updated_rows << en
        end
        return self
    end

    def delete
        @is_delete = true
        return self
    end

    def run
        if @is_select
            do_select
            if @is_where
                do_where
            end
            @table = @selected.dup
            @table.each do |row|
                print "#{row.to_hash}\n"
            end
        end
        if @is_insert
            writeCSV(@insert_or_update, @to_insert)
            # @to_insert.each do |row|
            #     p row.to_hash
            # end
            puts "Success".green
        
        elsif @is_update
            if @is_where
                do_where
            end
            if @update_delete_indexs.length < 1
                puts "Table not updated".red
                return self
            end
            temp = CSV::Table.new([], headers:@table.headers.dup)
            curr_index = 0
            for i in 0..@table.length-1 do 
                if @update_delete_indexs.include?(i)
                    temp << @updated_rows[@update_delete_indexs[curr_index]]
                    curr_index += 1
                else
                    temp << @table.by_row[i]        
                end
            end
            writeCSV(@insert_or_update, temp)
            puts "Success".green
        
        elsif @is_delete
            if @is_where
                do_where
            end
            if @update_delete_indexs.length < 1
                puts "Cannot delete. Criteria not found".red
                return self
            end
            @update_delete_indexs.each do |i|
                @table.delete(i)
            end
            if @to_delete != nil
                writeCSV(@to_delete, @table)
            end
            puts "Success".green
        end
    end
end

# req = MySqliteRequest.new
# # req.select(['name', 'position', 'year_start']).from("data.csv").order('asc', 'year_start').run
# req = req.select(['name', 'position', 'college', 'year_start'])
# req = req.from("data.csv")
# req = req.order("asc", 'year_start')
# # req = req.where('position', 'F')
# req.run

# ins = MySqliteRequest.new
# ins = ins.insert("newDB.csv")
# ins = ins.values(["2010", "Dilrabo","2013", "Sog'liqni saqlash", "160", "200", "Jul 7, 1991","STT kolleji"])
# ins.run

# up = MySqliteRequest.new
# up = up.update("newDB.csv")
# up = up.set({"college": "Qwasar SV"})
# up = up.where("year_start", "2010")
# up.run

# del = MySqliteRequest.new
# del = del.from("newDB.csv")
# del = del.delete
# del = del.where("name", "Holmon Alp")
# del.run

# jo = MySqliteRequest.new
# jo = jo.select(['name', 'type', 'team', 'year_start', 'college'])
# jo = jo.from('newDB.csv')
# jo = jo.join('year_end', 'sport.csv', 'year_start')
# jo = jo.where('college', 'Qwasar SV')
# jo.run
