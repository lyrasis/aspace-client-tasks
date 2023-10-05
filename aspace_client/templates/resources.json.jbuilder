json.title data["title"]
json.id_0 data["identifier"]
json.level data["level"]
case data["level"]
when "otherlevel"
  json.other_level "otherlevel"
end
json.extents do
  json.child! do
    json.number data["extent_number"]
    json.extent_type data["extent_type"]
    json.portion data["extent_portion"]
  end
end
json.dates do
  json.child! do
    json.date_type data["date_type"]
    json.label data["date_label"]
    json.expression data["date_expression"] unless data["date_expression"].nil?
    json.begin data["date_begin"] unless data["date_begin"].nil?
    json.end data["date_end"] unless data["date_end"].nil?
  end
end
json.lang_materials do
  json.child! do
    json.language_and_script do
      json.language "eng"
      json.script "Latn"
    end
  end
end
json.finding_aid_language "eng"
json.finding_aid_script "Latn"
