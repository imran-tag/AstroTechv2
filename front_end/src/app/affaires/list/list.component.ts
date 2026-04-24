import { Component } from '@angular/core';
import { AffairesService } from '../../_services/affaires/affaires.service';
import { SharedModule } from '../../_globale/shared/shared.module';
import { Router, RouterModule } from '@angular/router';
import { FichiersService } from '../../_services/fichiers/fichiers.service';
import { lastValueFrom } from 'rxjs';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-list',
  imports: [SharedModule, RouterModule],
  templateUrl: './list.component.html',
  styleUrl: './list.component.css'
})
export class ListComponent {
  today: Date = new Date(); // AJOUTEZ CETTE LIGNE
  affaires: any = [];
  selectedAffaire: any | null = null;
  loading = true;
  error: string | null = null;
  newFiles: File[] = [];
  url_upload = environment.url_upload;

  // ================= PAGINATION =================
  page = 1;             // page actuelle
  limit = 20;            // nombre d'éléments par page
  total = 0;            // total d'éléments côté backend
  searchTerm = '';      // texte de recherche

  constructor(
    private affaireService: AffairesService,
    private fichiersService: FichiersService,
    private router: Router
  ) { }

  ngOnInit(): void {
    this.loadAffaires();
  }

  isMenuOpen = false;

  toggleMenu() {
    this.isMenuOpen = !this.isMenuOpen;
  }

  // ✅ Getter pour afficher les noms des fichiers
  get newFilesNames(): string {
    return this.newFiles.length > 0
      ? this.newFiles.map(f => f.name).join(', ')
      : 'Aucun fichier choisi';
  }

  loadAffaires() {
    this.loading = true;

    this.affaireService.getAllPaginated(this.page, this.limit, this.searchTerm)
      .subscribe({
        next: (res: any) => {
          // ⚡ le backend doit renvoyer { data, page, limit, total }
          this.affaires = res.data;
          this.page = res.page;
          this.limit = res.limit;
          this.total = res.total;
          this.loading = false;
        },
        error: err => {
          console.error(err);
          this.error = 'Impossible de charger les affaires';
          this.loading = false;
        }
      });
  }

  searchAffaires() {
    this.page = 1; // revenir à la page 1 à chaque recherche
    this.loadAffaires();
  }

  // ================= PAGINATION METHODS =================
  get totalPages(): number[] {
    return Array.from(
      { length: Math.ceil(this.total / this.limit) },
      (_, i) => i + 1
    );
  }

  changePage(p: number) {
    if (p < 1 || p > this.totalPages.length) return;
    this.page = p;
    this.loadAffaires();
  }

  selectAffaire(affaire: any): void {
    this.selectedAffaire = affaire;
  }

  deleteAffaire(id: number) {
    if (confirm('Voulez-vous vraiment supprimer cette affaire ?')) {
      this.affaireService.delete(id).subscribe({
        next: () => {
          // Supprimer l'affaire du tableau local pour mise à jour UI instantanée
          this.loadAffaires();
          alert('Affaire supprimé avec succès !');
        },
        error: (err) => {
          console.error('Erreur lors de la suppression :', err);
          alert('Impossible de supprimer cette affaire.');
        }
      });
    }
  }

  /** Fichiers sélectionnés avant upload */
  onFileSelected(event: any) {
    const files: FileList = event.target.files;
    for (let i = 0; i < files.length; i++) {
      this.newFiles.push(files[i]);
    }
  }

  removeNewFile(index: number) {
    this.newFiles.splice(index, 1);
  }

  // /** Upload fichiers vers backend */
  // async uploadFiles() {
  //   if (!this.selectedAffaire || !this.newFiles || this.newFiles.length === 0) return;

  //   try {
  //     for (const file of this.newFiles) {
  //       const fd = new FormData();
  //       fd.append('files', file);
  //       fd.append('idAffaire', this.selectedAffaire.affaireId.toString());

  //       // Envoi au backend
  //       const res: any = await lastValueFrom(this.fichiersService.uploadFiles(fd));

  //       console.log("Réponse backend :", res.body);

  //       // Sécurité : vérifier que res.files est bien un tableau
  //       const uploadedFiles = Array.isArray(res.body.files) ? res.body.files : [];

  //       if (!this.selectedAffaire.fichiers) {
  //         this.selectedAffaire.fichiers = [];
  //       }

  //       // Ajouter les fichiers uploadés dans la liste affichée
  //       const nouveauxFichiers = uploadedFiles.map((f: any) => ({
  //         id: f.id,
  //         nom: f.originalname,
  //         chemin: f.filename,
  //         size: f.size,
  //         mimetype: f.mimetype
  //       }));

  //       //console.log('** nouveauxFichiers **',uploadedFiles);

  //       // ⚡ Créer une nouvelle référence pour déclencher la détection Angular
  //       this.selectedAffaire.fichiers = [...(this.selectedAffaire.fichiers || []), ...nouveauxFichiers];
  //     }

  //     // Vider la liste des fichiers sélectionnés
  //     this.newFiles = [];
  //   } catch (err) {
  //     console.error('Erreur upload', err);
  //     alert('Erreur lors de l\'upload des fichiers');
  //   }
  // }

  async uploadFiles() {
    if (!this.selectedAffaire || !this.newFiles || this.newFiles.length === 0) return;

    try {
      for (const file of this.newFiles) {
        const fd = new FormData();
        fd.append('files', file);
        fd.append('idAffaire', this.selectedAffaire.affaireId.toString());

        // Envoi au backend
        const res: any = await lastValueFrom(this.fichiersService.uploadFiles(fd));

        // On récupère les données de la réponse (ajustez selon votre structure API)
        const uploadedFiles = Array.isArray(res.body?.files) ? res.body.files : [];

        // Mapper les fichiers au format attendu par votre interface
        const nouveauxFichiers = uploadedFiles.map((f: any) => ({
          id: f.id,
          nom: f.originalname || f.nom,
          type: f.mimetype || f.type,
          chemin: f.filename || f.chemin
        }));

        // IMPORTANT : Utiliser le même nom que dans votre template HTML (fichiersJoints)
        if (!this.selectedAffaire.fichiersJoints) {
          this.selectedAffaire.fichiersJoints = [];
        }

        // Mise à jour de la liste avec un nouveau tableau (Spread operator) 
        // Cela force Angular à rafraîchir la vue immédiatement
        this.selectedAffaire.fichiersJoints = [
          ...this.selectedAffaire.fichiersJoints,
          ...nouveauxFichiers
        ];
      }

      // Réinitialisation
      this.newFiles = [];
      console.log("Liste mise à jour :", this.selectedAffaire.fichiersJoints);

    } catch (err) {
      console.error('Erreur upload', err);
    }
  }

  /** Supprimer un fichier uploadé */
  removeUploadedFile(fichierId: number) {
    if (!confirm('Voulez-vous supprimer ce fichier ?')) return;

    this.fichiersService.deleteById(fichierId).subscribe({
      next: () => {
        if (this.selectedAffaire && this.selectedAffaire.fichiers) {
          this.selectedAffaire.fichiers = this.selectedAffaire.fichiers.filter((f: any) => f.id !== fichierId);
        }
      },
      error: err => {
        console.error('Erreur suppression fichier', err);
        alert('Impossible de supprimer le fichier');
      }
    });
  }

  // navigation vers le formulaire d'ajout
  goToAddAffaire() {
    this.router.navigate(['/affaires/edit']);
  }

  // navigation vers le formulaire de modification
  goToEditAffaire(affaire: any) {
    this.router.navigate(['/affaires/edit', affaire.affaireId]);
  }

  goToAddLinkedAffaire(affaire: any) {
    this.router.navigate(
      ['/interventions/edit'],
      { queryParams: { affaireId: affaire.affaireId } }
    );
  }

}