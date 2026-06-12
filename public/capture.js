function captureApp() {
  return {
    state: 'capture',
    preview: null,
    dragging: false,
    activeRef: null,

    handleFile(file, ref) {
      if (!file) return;
      this.activeRef = ref;
      this.preview = file.type.startsWith('image/') ? URL.createObjectURL(file) : null;
      this.state = 'saved';
    },

    onCameraInput(e) { this.handleFile(e.target.files[0], 'cameraInput'); },
    onFileInput(e)   { this.handleFile(e.target.files[0], 'fileInput'); },

    onDrop(e) {
      this.dragging = false;
      const file = e.dataTransfer?.files[0];
      if (file) {
        this.$refs.fileInput.files = e.dataTransfer.files;
        this.handleFile(file, 'fileInput');
      }
    },

    onSubmit() {
      const inactive = this.activeRef === 'cameraInput' ? this.$refs.fileInput : this.$refs.cameraInput;
      inactive.disabled = true;
    },

    reset() {
      if (this.preview) URL.revokeObjectURL(this.preview);
      this.state = 'capture';
      this.preview = null;
      this.activeRef = null;
      this.$refs.fileInput.disabled = false;
      this.$refs.cameraInput.disabled = false;
      this.$refs.fileInput.value = '';
      this.$refs.cameraInput.value = '';
    }
  }
}
