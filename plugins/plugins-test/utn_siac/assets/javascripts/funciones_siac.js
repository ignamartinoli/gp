function getNombreTitulacion(num) {
    var titulacion = parseInt(num); 
    switch (titulacion) { 
        case 1:
            return "Licenciaturas";
            break;
        case 2:
            return "Ingenierías";
            break;
        case 3:
            return "Terciarios";
            break;
        case 4:
            return "Tecnicaturas";
            break;
        case 5:
            return "Maestrías";
            break;
        case 6:
            return "Doctorados";
            break;
        default:
            return "-";
            break;
    }
}