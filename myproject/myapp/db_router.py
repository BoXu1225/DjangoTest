class MultiServerDatabaseRouter:
    """
    A router to control all database operations on models for different servers
    """

    def db_for_read(self, model, **hints):
        """Suggest the database to read from."""
        # Use default database for reads unless specifically routed
        return None

    def db_for_write(self, model, **hints):
        """Suggest the database to write to."""
        # Use default database for writes unless specifically routed
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """Ensure that certain models get created on the right database."""
        # Allow migrations on all databases
        return True

    def allow_relation(self, obj1, obj2, **hints):
        """Allow relations if the models are in the same database."""
        db_set = {'default'}
        # Add all server databases
        for i in range(1, 3):  # Assuming 2 servers
            db_set.add(f'server_{i}')

        if obj1._meta.app_label in db_set and obj2._meta.app_label in db_set:
            return True
        return None