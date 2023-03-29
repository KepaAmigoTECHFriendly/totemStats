library(httr)
library(jsonlite)
library(lubridate)

while (TRUE) {
  hora <- hour(Sys.time()) + 1
  if(hora == 11){
    #-----------------------------------------------------------------
    # GET NÚMERO DE VISITAS DIARIA EN TOTEM https://contenidos.plasencia.es
    #-----------------------------------------------------------------
    endpoint <- "http://wordpress:80/wp-json/slimstat/v1/get?token=d308a42a72b125df2abd6283283de87a&function=recent&dimension=*&filters=interval%20equals%20-1" # Endpoint de la API de Slimstat
    
    response <- GET(endpoint, add_headers("Content-Type"="application/json","Accept"="application/json"))
    
    if (status_code(response) == 200) {
      data <- fromJSON(content(response, as = "text"))
      
      df <- data.frame(data$data)
      df_no_admin <- df[is.na(df$username),]
      df_no_admin <- df_no_admin[!is.na(df_no_admin$resource),]
      df_no_admin <- df_no_admin[-grep("wp-",df_no_admin$resource),]
      df_no_admin <- df_no_admin[df_no_admin$platform == "win10",]
      
      visitas <- length(unique(df_no_admin$visit_id))
    } else {
      cat("Error al obtener los datos de Slimstat.\n")
    }
    
    
    
    # ------------------------------------------------------------------------------
    # PETICIÓN TOKENs THB
    # ------------------------------------------------------------------------------
    
    cuerpo <- '{"username":"kepa@techfriendly.es","password":"kepatech"}'
    post <- httr::POST(url = "http://plataforma:9090/api/auth/login",
                       add_headers("Content-Type"="application/json","Accept"="application/json"),
                       body = cuerpo,
                       verify= FALSE,
                       encode = "json",verbose()
    )
    
    resultado_peticion_token <- httr::content(post)
    auth_thb <- paste("Bearer",resultado_peticion_token$token)
    
    
    # ------------------------------------------------------------------------------
    # ENVÍO DATOS TELEMETRÍA A DISPOSITIVO Tótem
    # ------------------------------------------------------------------------------
    
    url <- "http://plataforma:9090/api/plugins/telemetry/DEVICE/66e27620-900f-11ed-88c5-0b914657332e/timeseries/ANY?scope=ANY"
    json_envio_plataforma <- paste('{"visitas_dia":', visitas,'}',sep = "")
    post <- httr::POST(url = url,
                       add_headers("Content-Type"="application/json","Accept"="application/json","X-Authorization"=auth_thb),
                       body = json_envio_plataforma,
                       verify= FALSE,
                       encode = "json",verbose()
    )
  }
  Sys.sleep(1800)
}

