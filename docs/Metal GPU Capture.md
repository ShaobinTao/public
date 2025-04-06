


# Issues and Solutions
## Unable to create shader debug session, "Source is unavailble"
- make sure "Build Settings" | Deployment | "<whatever OS> Deployment Target" match host OS version. 
- "Metal compiler - Build Options" -> "Produce Debugging Information", I set the value to "Yes, include source code".
- Edit Scheme | GPU Frame Capture - select "Metal"



