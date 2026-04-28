using Alcoholimetro.Application.Commands;
using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Enums;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;
using FluentAssertions;
using Moq;

namespace Alcoholimetro.Application.Tests.Commands;

public class JoinGroupCommandHandlerTests
{
    private readonly Mock<IGroupRepository> _groupRepositoryMock;
    private readonly JoinGroupCommandHandler _handler;

    public JoinGroupCommandHandlerTests()
    {
        _groupRepositoryMock = new Mock<IGroupRepository>();
        _handler = new JoinGroupCommandHandler(_groupRepositoryMock.Object);
    }

    [Fact]
    public async Task ExecuteAsync_WithValidCode_AddsUserToGroup()
    {
        // Arrange
        var command = new JoinGroupCommand(Guid.NewGuid(), "VALID_CODE");
        var group = new Group { Id = Guid.NewGuid(), Name = "Test Group", InvitationCode = "VALID_CODE" };
        
        _groupRepositoryMock.Setup(x => x.GetByInvitationCodeAsync(command.InvitationCode))
            .ReturnsAsync(group);
            
        _groupRepositoryMock.Setup(x => x.IsUserInGroupAsync(command.UserId, group.Id))
            .ReturnsAsync(false);

        // Act
        await _handler.ExecuteAsync(command);

        // Assert
        _groupRepositoryMock.Verify(x => x.AddUserToGroupAsync(It.Is<UserGroup>(ug => 
            ug.UserId == command.UserId && 
            ug.GroupId == group.Id && 
            ug.Role == GroupRole.Member)), Times.Once);
    }

    [Fact]
    public async Task ExecuteAsync_WithInvalidCode_ThrowsException()
    {
        // Arrange
        var command = new JoinGroupCommand(Guid.NewGuid(), "INVALID_CODE");
        
        _groupRepositoryMock.Setup(x => x.GetByInvitationCodeAsync(command.InvitationCode))
            .ReturnsAsync((Group)null);

        // Act
        Func<Task> act = async () => await _handler.ExecuteAsync(command);

        // Assert
        await act.Should().ThrowAsync<NotFoundException>()
            .WithMessage("El código de invitación no existe.");
        
        _groupRepositoryMock.Verify(x => x.AddUserToGroupAsync(It.IsAny<UserGroup>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WhenAlreadyMember_ThrowsException()
    {
        // Arrange
        var command = new JoinGroupCommand(Guid.NewGuid(), "VALID_CODE");
        var group = new Group { Id = Guid.NewGuid(), Name = "Test Group", InvitationCode = "VALID_CODE" };
        
        _groupRepositoryMock.Setup(x => x.GetByInvitationCodeAsync(command.InvitationCode))
            .ReturnsAsync(group);
            
        _groupRepositoryMock.Setup(x => x.IsUserInGroupAsync(command.UserId, group.Id))
            .ReturnsAsync(true);

        // Act
        Func<Task> act = async () => await _handler.ExecuteAsync(command);

        // Assert
        await act.Should().ThrowAsync<ConflictException>()
            .WithMessage("Ya eres miembro de este grupo.");
            
        _groupRepositoryMock.Verify(x => x.AddUserToGroupAsync(It.IsAny<UserGroup>()), Times.Never);
    }
}
