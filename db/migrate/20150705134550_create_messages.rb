class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|

      # These fields are actually all storing binary data, but they are stored
      # is hex values, so the database simply sees them as strings.
      t.string :source
      t.string :destination

      # These fields are encrypted
      t.json :metadata
      t.json :body

      t.index %i(destination source)
    end
  end
end
