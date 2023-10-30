"""spell_table

Revision ID: d4d2b2fce5f8
Revises: 3fb13bacd9e0
Create Date: 2023-07-25 16:37:15.732591

"""
import sqlalchemy as sa
from alembic import op

from dnd5esheets.models import Json

# revision identifiers, used by Alembic.
revision = "d4d2b2fce5f8"
down_revision = "3fb13bacd9e0"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table(
        "spell",
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("level", sa.Integer(), nullable=False),
        sa.Column("school", sa.String(length=1), nullable=False),
        sa.Column("json_data", Json(), nullable=False),
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    with op.batch_alter_table("spell", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_spell_created_at"), ["created_at"], unique=False)
        batch_op.create_index(batch_op.f("ix_spell_name"), ["name"], unique=True)

    # ### end Alembic commands ###


def downgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table("spell", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_spell_name"))
        batch_op.drop_index(batch_op.f("ix_spell_created_at"))

    op.drop_table("spell")
    # ### end Alembic commands ###
