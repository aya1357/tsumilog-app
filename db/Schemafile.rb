create_table 'posts', force: :cascade do |t|
  t.string 'title', null: false
  t.text 'content'
  t.timestamps
end
