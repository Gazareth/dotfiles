os: windows
-
show names [once]:
    labels.show_query_names('[is_content_element=1][rect]:is([patterns*="Invoke"], [patterns*="Toggle"], [patterns*="SelectionItem"], [patterns*="LegacyIAccessible"])')
show numbers [once]:
    labels.show_query('[is_content_element=1][rect]:is([patterns*="Invoke"], [patterns*="Toggle"], [patterns*="SelectionItem"], [patterns*="LegacyIAccessible"])')
show menu numbers:
    labels.show_query('[control_type="MenuItem"]:is([patterns*="Invoke"], [patterns*="Toggle"], [patterns*="SelectionItem"], [patterns*="LegacyIAccessible"])')
