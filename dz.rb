require "google_drive"
session = GoogleDrive::Session.from_config("config.json")
def clean(matrix)
    br = matrix.index { |row| !row.all? { |cell| cell == "" } }  # vraca index prvog reda koji nije prazan (ako ne postoji onda vraca null)
    br = 0 if br == nil
    matrix.shift(br)
end

class Klasa
    include Enumerable
    attr_reader (:spreadsheet),(:worksheet),(:matrix),(:headers),(:title)
    def initialize(session,key,title)
        @spreadsheet = session.spreadsheet_by_key(key)
        @worksheet = @spreadsheet.worksheet_by_title(title)
    end
    def load_to_matrix(worksheet)
        @matrix = worksheet.rows.dup   # da ne bi matrica bila zaledjena
        clean(@matrix)                  # brise prazne redove
        matrix.delete_if { |row| row.any? { |cell| cell.to_s.downcase.include?('total') || cell.to_s.downcase.include?('subtotal') } }
        @matrix = @matrix.transpose
        clean(@matrix)                  # brise prazne kolone
        @headers = matrix.transpose[0]
    end
    def row(i)
        matrix.transpose[i+1]
    end
    def each
        matrix.each do |row|
            row.each do |cell|
                yield cell
            end
        end
    end
    def [](name)
        matrix.each do |column|
            return Helper.new(column,matrix.index(column),self) if column.include? name
        end
        nil
    end
    def method_missing(name,*args)
        raise "Method must not have any arguments" if args.size > 0
        name = name.to_s
        col = matrix.find { |column| column[0].delete(" ") == name}
        return Helper.new(col,matrix.index(col),self)
    end
    def add_tables(t2)

        raise "Tables must have the same headers for addition" unless headers == t2.headers
        #transponujem jer mi je lakse da dodajem redove nego kolone(inace ih cuvam kao kolone)
        result_matrix = matrix.transpose
        #dodavanje bez headera
        result_matrix += t2.matrix.transpose[1..-1]
    end
    def subtract_tables(t2)
        raise "Tables must have the same headers for addition" unless headers == t2.headers
        result_matrix = []
        #dodaje sve redove iz prve tabele koji nisu u drugoj, ali ne gleda headere
        result_matrix += @matrix.transpose.reject { |row| t2.matrix.transpose[1..-1].include?(row) }
    end
end

inst = Klasa.new(session,"1J2Uz1DdNDErACwhB4u28vyAGKJJGCbDEojgwuqFDS5E","Sheet1");
inst.load_to_matrix(inst.worksheet)

class Helper
    include Enumerable
    attr_accessor (:array)
    attr_accessor (:index)
    attr_accessor (:inst)
    def initialize(array,index,inst)
        @array = array
        @index = index
        @inst = inst
    end
    def [](i)
        @array[i+1]
    end
    def []=(i,value)
        @array[i+1] = value
    end
    def to_s
        @array[1..-1].to_s
    end
    def sum
        @array.sum(&:to_i)
    end

    def avg
        1.0 * sum / (@array.size - 1)
    end
    def method_missing(name,*args)
        raise "Method must not have any arguments" if args.size > 0
        name = name.to_s
        inst.matrix.transpose.each do |row|
            if row[index] == name
                return row
            end
        end
        nil
    end
    def each
        array.each do |cell|
            yield cell
        end
    end
end

puts inst["Druga Kolona"]
puts inst["Druga Kolona"][1]
inst["Druga Kolona"][1] = 50
puts inst["Druga Kolona"][1]
puts inst["Druga Kolona"]
p inst.row(1)
inst["Prva Kolona"][1] = "rn"
p inst.PrvaKolona.sum
p inst.PrvaKolona.avg
p inst.PrvaKolona.rn 
p inst.PrvaKolona.reduce &:+
#p inst.spreadsheet
#p inst.worksheet
p inst.PrvaKolona.map {  |x| (x.to_i > 0 || x == 0) ? (x.to_i)+1 : x}
p inst.DrugaKolona.select {|x| (x.to_i)>0}
puts inst.PrvaKolona
p inst.matrix

second = Klasa.new(session,"1J2Uz1DdNDErACwhB4u28vyAGKJJGCbDEojgwuqFDS5E","Sheet2");
second.load_to_matrix(second.worksheet)
p second.matrix

lala = inst.add_tables(second)
p lala.transpose
ok = inst.subtract_tables(second)
p ok.transpose
#puts( inst.PrvaKolona.map &:upcase)
#p inst.matrix
#p inst.headers
#p inst.row(1)
#inst["Druga Kolona"] do |cell|
#    p cell
#end
#inst.each do |cell|
#    p cell
#end

