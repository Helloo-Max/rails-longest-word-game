////////////////////
// Default Config //
////////////////////

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import "channels"

Rails.start()
Turbolinks.start()


///////////////////
// Custom Config //
///////////////////

// Requirements
require('jquery')


// Imports
import { initEasyTimer } from "../plugins/init_easytimer"


// Plugins
initEasyTimer();
