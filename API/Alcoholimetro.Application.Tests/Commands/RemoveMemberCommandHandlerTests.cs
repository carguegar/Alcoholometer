using Alcoholimetro.Application.Commands;
using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Enums;
using Alcoholimetro.Domain.Repositories;
using FluentAssertions;
using Moq;

namespace Alcoholimetro.Application.Tests.Commands;

public class RemoveMemberCommandHandlerTests
{
    private readonly Mock<IGroupRepository> _groupRepositoryMock;
    private readonly RemoveMemberCommandHandler _handler;

    public RemoveMemberCommandHandlerTests()
    {
        _groupRepositoryMock = new Mock<IGroupRepository>();
        _handler = new RemoveMemberCommandHandler(_groupRepositoryMock.Object);
    }

    [Fact]
    public async Task ExecuteAsync_WhenAdminLeavesAndOtherMembersExist_TransfersAdminToOldestRemainingMember()
    {
        // Arrange
        var groupId = Guid.NewGuid();
        var userAId = Guid.NewGuid();
        var userBId = Guid.NewGuid();
        var userCId = Guid.NewGuid();

        var adminUserGroup = new UserGroup
        {
            UserId = userAId,
            GroupId = groupId,
            Role = GroupRole.Admin,
            JoinedAt = DateTime.UtcNow.AddMonths(-3)
        };

        var remainingGroup = new Group
        {
            Id = groupId,
            Name = "Test Group",
            Members = new List<UserGroup>
            {
                new UserGroup
                {
                    UserId = userBId,
                    GroupId = groupId,
                    Role = GroupRole.Member,
                    JoinedAt = DateTime.UtcNow.AddMonths(-2)
                },
                new UserGroup
                {
                    UserId = userCId,
                    GroupId = groupId,
                    Role = GroupRole.Member,
                    JoinedAt = DateTime.UtcNow.AddMonths(-1)
                }
            }
        };

        _groupRepositoryMock.Setup(x => x.GetUserGroupAsync(userAId, groupId))
            .ReturnsAsync(adminUserGroup);
        _groupRepositoryMock.Setup(x => x.GetGroupMemberCountAsync(groupId))
            .ReturnsAsync(2);
        _groupRepositoryMock.Setup(x => x.GetGroupWithMembersAsync(groupId))
            .ReturnsAsync(remainingGroup);

        var command = new RemoveMemberCommand(userAId, userAId, groupId);

        // Act
        await _handler.ExecuteAsync(command);

        // Assert
        _groupRepositoryMock.Verify(x => x.RemoveUserFromGroupAsync(userAId, groupId), Times.Once);
        _groupRepositoryMock.Verify(x => x.UpdateUserGroupRoleAsync(userBId, groupId, GroupRole.Admin), Times.Once);
        remainingGroup.Members.First(m => m.UserId == userCId).Role.Should().Be(GroupRole.Member);
        _groupRepositoryMock.Verify(x => x.DeleteGroupAsync(It.IsAny<Guid>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WhenLastMemberLeaves_DeletesGroup()
    {
        // Arrange
        var groupId = Guid.NewGuid();
        var userAId = Guid.NewGuid();

        var adminUserGroup = new UserGroup
        {
            UserId = userAId,
            GroupId = groupId,
            Role = GroupRole.Admin,
            JoinedAt = DateTime.UtcNow.AddMonths(-3)
        };

        _groupRepositoryMock.Setup(x => x.GetUserGroupAsync(userAId, groupId))
            .ReturnsAsync(adminUserGroup);
        _groupRepositoryMock.Setup(x => x.GetGroupMemberCountAsync(groupId))
            .ReturnsAsync(0);

        var command = new RemoveMemberCommand(userAId, userAId, groupId);

        // Act
        await _handler.ExecuteAsync(command);

        // Assert
        _groupRepositoryMock.Verify(x => x.RemoveUserFromGroupAsync(userAId, groupId), Times.Once);
        _groupRepositoryMock.Verify(x => x.DeleteGroupAsync(groupId), Times.Once);
        _groupRepositoryMock.Verify(x => x.UpdateAsync(It.IsAny<Group>()), Times.Never);
        _groupRepositoryMock.Verify(x => x.GetGroupWithMembersAsync(It.IsAny<Guid>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WhenNonAdminLeaves_DoesNotTransferAdmin()
    {
        // Arrange
        var groupId = Guid.NewGuid();
        var userBId = Guid.NewGuid();

        var memberUserGroup = new UserGroup
        {
            UserId = userBId,
            GroupId = groupId,
            Role = GroupRole.Member,
            JoinedAt = DateTime.UtcNow.AddMonths(-1)
        };

        _groupRepositoryMock.Setup(x => x.GetUserGroupAsync(userBId, groupId))
            .ReturnsAsync(memberUserGroup);
        _groupRepositoryMock.Setup(x => x.GetGroupMemberCountAsync(groupId))
            .ReturnsAsync(1);

        var command = new RemoveMemberCommand(userBId, userBId, groupId);

        // Act
        await _handler.ExecuteAsync(command);

        // Assert
        _groupRepositoryMock.Verify(x => x.RemoveUserFromGroupAsync(userBId, groupId), Times.Once);
        _groupRepositoryMock.Verify(x => x.UpdateAsync(It.IsAny<Group>()), Times.Never);
        _groupRepositoryMock.Verify(x => x.DeleteGroupAsync(It.IsAny<Guid>()), Times.Never);
        _groupRepositoryMock.Verify(x => x.GetGroupWithMembersAsync(It.IsAny<Guid>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WhenAdminKicksAnotherAdmin_RemainingAdminStays()
    {
        // Arrange
        var groupId = Guid.NewGuid();
        var userAId = Guid.NewGuid();
        var userBId = Guid.NewGuid();
        var userCId = Guid.NewGuid();

        var requestingAdmin = new UserGroup
        {
            UserId = userAId,
            GroupId = groupId,
            Role = GroupRole.Admin,
            JoinedAt = DateTime.UtcNow.AddMonths(-3)
        };

        var targetAdmin = new UserGroup
        {
            UserId = userBId,
            GroupId = groupId,
            Role = GroupRole.Admin,
            JoinedAt = DateTime.UtcNow.AddMonths(-2)
        };

        var remainingGroup = new Group
        {
            Id = groupId,
            Name = "Test Group",
            Members = new List<UserGroup>
            {
                new UserGroup
                {
                    UserId = userAId,
                    GroupId = groupId,
                    Role = GroupRole.Admin,
                    JoinedAt = DateTime.UtcNow.AddMonths(-3)
                },
                new UserGroup
                {
                    UserId = userCId,
                    GroupId = groupId,
                    Role = GroupRole.Member,
                    JoinedAt = DateTime.UtcNow.AddMonths(-1)
                }
            }
        };

        _groupRepositoryMock.Setup(x => x.GetUserGroupAsync(userBId, groupId))
            .ReturnsAsync(targetAdmin);
        _groupRepositoryMock.Setup(x => x.GetUserGroupAsync(userAId, groupId))
            .ReturnsAsync(requestingAdmin);
        _groupRepositoryMock.Setup(x => x.GetGroupMemberCountAsync(groupId))
            .ReturnsAsync(2);
        _groupRepositoryMock.Setup(x => x.GetGroupWithMembersAsync(groupId))
            .ReturnsAsync(remainingGroup);

        var command = new RemoveMemberCommand(userAId, userBId, groupId);

        // Act
        await _handler.ExecuteAsync(command);

        // Assert
        _groupRepositoryMock.Verify(x => x.RemoveUserFromGroupAsync(userBId, groupId), Times.Once);
        _groupRepositoryMock.Verify(x => x.UpdateAsync(It.IsAny<Group>()), Times.Never);
        _groupRepositoryMock.Verify(x => x.DeleteGroupAsync(It.IsAny<Guid>()), Times.Never);
        remainingGroup.Members.First(m => m.UserId == userCId).Role.Should().Be(GroupRole.Member);
        remainingGroup.Members.First(m => m.UserId == userAId).Role.Should().Be(GroupRole.Admin);
    }
}
