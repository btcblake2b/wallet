// Conditional export: la consegna dell'export cambia per piattaforma.
//
// // PERCHÉ: sul web l'utente non ha un file manager a portata di mano → si
// // scarica il file dal browser; su mobile/desktop si usa la clipboard.
// // Nessuna dipendenza nuova (niente path_provider/share_plus): la clipboard è
// // nel framework e `dart:html` è già usato dalle varianti web del progetto.
export 'export_delivery_io.dart'
    if (dart.library.html) 'export_delivery_web.dart';
