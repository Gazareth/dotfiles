os: mac
-
show names [once]:
    labels.show_query_names("[AXPosition]:action(AXPress)")
show numbers [once]:
    labels.show_query("[AXPosition]:action(AXPress)")
show menu numbers:
    labels.show_query('[AXRole="AXMenuItem"]')
