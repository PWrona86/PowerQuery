(input_col as text, optional input_list as list) as text =>
  let
    // Step 1: Prepare list of capital letter positions if not passed
    positions_list =
      if input_list = null then
        List.RemoveItems(Text.PositionOfAny(input_col, List.Transform({"A".."Z"}, each _), Occurrence.All), {0})
      else
        input_list,

    // Step 2: Transform Text (recursive helper function)
    ProcessText = (txt as text, positions as list) as text =>
      if List.IsEmpty(positions) then
        Text.Lower(txt)
      else if List.Count(positions) = 1 then
        let
          index = positions{0},
          new_text = Text.Insert(txt, index, "_")
        in
          Text.Lower(new_text)
      else
        let
          index = positions{0},
          new_text = Text.Insert(txt, index, "_"),
          new_list = List.Skip(positions, 1),
          // Adjust remaining positions by 1 since we inserted a character
          adjusted_list = List.Transform(new_list, each _ + 1)
        in
          @ProcessText(new_text, adjusted_list),

    result = ProcessText(input_col, positions_list)
  in
    result
