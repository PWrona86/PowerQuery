let
    Source = Sql.Database(SQLServerName, SQLServerDB),
    Navigation = Source{[Schema = "dbo", Item = "CURR_ENTITY"]}[Data],

    Divisions = {"EMEAop", "AMop", "AMop_incl_HHI", "GCSEAop", "PNEAop", "HIDITGGRop", "HOTELLOCK", "AAESGGRop"},

    // Recursive path builder
    pathFunctionUp = (childCol as text, parentCol as text, currentNodes as list, pathSoFar as text) as list =>
        let
            // Get parent rows for current child nodes
            parentRows = Table.SelectRows(Navigation, each List.Contains(currentNodes, Record.Field(_, childCol))),
            parents = List.RemoveMatchingItems(List.Distinct(Table.Column(parentRows, parentCol)), {null, ""}),
            
            // stopHere = List.MatchesAny(currentNodes, each List.Contains(Divisions, _)),

            // Build paths
            paths =
                if List.IsEmpty(parents) then
                    { Text.Combine(List.Reverse(Text.Split(pathSoFar, "|")), "|") }
                else
                    List.Combine(
                        List.Transform(parents, each 
                            @pathFunctionUp(childCol, parentCol, {_}, pathSoFar & "|" & _)
                        )
                    )
        in
            paths,

    // Add upward paths column
    #"Add Path" = Table.AddColumn(Navigation, "Path", each
        
        //if List.Contains(Divisions, [Label]) then { [Label] }
        if [Label] = "[None]" or [ParentLabel] = null or [ParentLabel] = "" then 
            { [Label] } 
        else 
            pathFunctionUp("Label", "ParentLabel", {[ParentLabel]}, [Label] & "|" & [ParentLabel])
    ),

    #"Expanded Path" = Table.ExpandListColumn(#"Add Path", "Path"),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded Path", {{"Path", type text}})

in
    #"Changed column type"
