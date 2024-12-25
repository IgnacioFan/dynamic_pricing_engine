namespace :import_csv do
  desc "Import data from inventory.csv file. Run rake import_csv:inventory[PATH]"
  task :inventory, [ :file_path ] => :environment do |_, args|
    file_path = args[:file_path]
    validate_file(file_path)

    ImportInventoryCsvService.call(file_path)
  end

  def validate_file(file_path)
    message = if file_path.nil?
                "File path is required"
    elsif !File.exist?(file_path)
                "File not found! #{file_path}"
    elsif File.extname(file_path) != ".csv"
                "Only CSV file is allowed! #{file_path}"
    else
                ""
    end

    if message.present?
      puts message
      exit 1
    end
  end
end
