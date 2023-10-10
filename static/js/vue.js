const { createApp, ref } = Vue;

createApp({
    setup() {
        const tree = fetch(`/api/trees/${treeId}`);
        const message = ref('Hello vue!');

        return {
            message
        };
    }
}).mount('#app');
