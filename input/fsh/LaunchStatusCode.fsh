CodeSystem:     LaunchStatusCode
Id:             launch-status-code-system
Title:          "LaunchStatusCode"
Description:    "An enumerated set of launch result states."
* ^caseSensitive = true
* #success "Successful"
    "A requested activity launch was successful."
* #error "Failure"
    "A requested activity launch failed."
